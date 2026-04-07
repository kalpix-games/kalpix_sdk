import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'kalpix_config.dart';
import 'kalpix_exception.dart';
import 'kalpix_session.dart';
import 'match_models.dart';
import 'rpc_response.dart';

typedef SocketMessageHandler = void Function(Map<String, dynamic> message);

/// WebSocket client for real-time communication with the Kalpix backend.
///
/// Uses the backend's type-discriminated envelope protocol:
///   Client sends:  {"type": "<msg_type>", "cid": "1", "<msg_type>": {...}}
///   Server sends:  {"type": "<msg_type>", "cid": "1", "<msg_type>": {...}}
///
/// CID-based correlation is used for request/response matching.
class KalpixSocketClient {
  final KalpixConfig config;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _matchDataController = StreamController<KalpixMatchData>.broadcast();
  final _matchPresenceController =
      StreamController<KalpixMatchPresenceEvent>.broadcast();
  final _pendingRequests = <String, Completer<Map<String, dynamic>>>{};

  int _cidCounter = 0;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream of real-time match data payloads.
  Stream<KalpixMatchData> get onMatchData => _matchDataController.stream;

  /// Stream of match presence events (players joining/leaving).
  Stream<KalpixMatchPresenceEvent> get onMatchPresence =>
      _matchPresenceController.stream;

  bool get isConnected => _connected;

  KalpixSocketClient({required this.config});

  /// Connect to the Kalpix WebSocket using the provided session token.
  Future<void> connect(KalpixSession session) async {
    if (_connected) return;

    final uri = Uri.parse(config.buildWsUrl(session.token));
    _channel = WebSocketChannel.connect(uri);

    final completer = Completer<void>();

    _subscription = _channel!.stream.listen(
      (raw) {
        if (!completer.isCompleted) completer.complete();
        _handleIncoming(raw as String);
      },
      onError: (error) {
        _connected = false;
        if (!completer.isCompleted) completer.completeError(error);
        _messageController.addError(error);
        _failPending('Connection error: $error');
      },
      onDone: () {
        _connected = false;
        if (!completer.isCompleted) completer.complete();
        _failPending('WebSocket connection closed');
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw const KalpixSocketException(
          message: 'WebSocket connection timed out'),
    );

    _connected = true;
  }

  /// Disconnect from the WebSocket.
  Future<void> disconnect() async {
    _connected = false;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _failPending('Disconnected');
  }

  /// Join a real-time match by match ID.
  Future<KalpixMatch> joinMatch(String matchId) async {
    _assertConnected();
    final cid = _nextCid();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cid] = completer;

    _send({
      'type': 'match_join',
      'cid': cid,
      'match_join': {'match_id': matchId},
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingRequests.remove(cid);
        throw KalpixSocketException(message: 'joinMatch "$matchId" timed out');
      },
    );

    // Server responds with type=match_joined; we extract the match_joined payload
    final matchJoined =
        result['match_joined'] as Map<String, dynamic>? ?? result;
    return KalpixMatch.fromMap(matchJoined);
  }

  /// Leave a real-time match.
  Future<void> leaveMatch(String matchId) async {
    if (!_connected || _channel == null) return;
    _send({
      'type': 'match_leave',
      'match_leave': {'match_id': matchId},
    });
  }

  /// Send binary/JSON data to a match with a given op-code.
  void sendMatchData({
    required String matchId,
    required int opCode,
    required Uint8List data,
  }) {
    _assertConnected();
    _send({
      'type': 'match_data',
      'match_data': {
        'match_id': matchId,
        'op_code': opCode,
        'data': base64Encode(data),
      },
    });
  }

  /// Send an RPC call over the WebSocket and await the correlated response.
  Future<Map<String, dynamic>> rpc(
      String functionId, Map<String, dynamic> payload) async {
    _assertConnected();

    final cid = _nextCid();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cid] = completer;

    _send({
      'type': 'rpc_request',
      'cid': cid,
      'rpc_request': {
        'id': functionId,
        'payload': jsonEncode(payload),
      },
    });

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(cid);
        throw KalpixSocketException(message: 'RPC "$functionId" timed out');
      },
    );
  }

  // ── Incoming message handler ─────────────────────────────────────────────

  void _handleIncoming(String raw) {
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = envelope['type'] as String? ?? '';
    final cid = envelope['cid'] as String?;

    // ── Correlated request/response (has CID) ──
    if (cid != null && _pendingRequests.containsKey(cid)) {
      final completer = _pendingRequests.remove(cid)!;

      switch (type) {
        case 'rpc_response':
          _completeRpc(completer, envelope);
          return;

        case 'match_joined':
          // Return the full envelope so joinMatch() can extract match_joined
          completer.complete(envelope);
          return;

        case 'error':
          final err = envelope['error'] as Map<String, dynamic>?;
          completer.completeError(KalpixException(
            errorCode:
                err?['code'] as int? ?? KalpixException.internalError,
            message: err?['message'] as String? ?? 'Unknown error',
          ));
          return;

        case 'pong':
          completer.complete({});
          return;

        default:
          // Unknown correlated response — complete with full envelope
          completer.complete(envelope);
          return;
      }
    }

    // ── Server-initiated push messages (no CID) ──
    switch (type) {
      case 'match_data':
        _handleMatchData(envelope);
        return;

      case 'match_presence_event':
        _handleMatchPresence(envelope);
        return;

      case 'stream_data':
        _handleStreamData(envelope);
        return;

      case 'notification':
        _handleNotification(envelope);
        return;

      case 'stream_presence_event':
      case 'presence_update':
        // Broadcast push — forward to the messages stream
        _messageController.add(envelope);
        return;

      case 'error':
        // Uncorrelated error (server-initiated)
        _messageController.add(envelope);
        return;

      case 'pong':
        // Ignore unsolicited pong
        return;

      default:
        // Forward any unrecognised push message
        _messageController.add(envelope);
        return;
    }
  }

  void _completeRpc(
      Completer<Map<String, dynamic>> completer, Map<String, dynamic> envelope) {
    final rpcField = envelope['rpc_response'] as Map<String, dynamic>?;
    if (rpcField == null) {
      completer.complete({});
      return;
    }

    final payloadStr = rpcField['payload'] as String?;
    Map<String, dynamic> payloadMap = {};
    if (payloadStr != null && payloadStr.isNotEmpty) {
      try {
        payloadMap = jsonDecode(payloadStr) as Map<String, dynamic>;
      } catch (_) {
        payloadMap = {'raw': payloadStr};
      }
    }

    final rpcResponse = RpcResponse.parse(payloadMap);
    if (rpcResponse.isError) {
      completer.completeError(KalpixException(
        errorCode: rpcResponse.errorCode ?? KalpixException.internalError,
        message: rpcResponse.errorMessage.isNotEmpty
            ? rpcResponse.errorMessage
            : 'RPC error',
      ));
    } else {
      completer.complete(rpcResponse.formattedData);
    }
  }

  /// Unwrap a `stream_data` envelope.
  ///
  /// The backend sends: `{"type":"stream_data","stream_data":{"data":"<json>","sender":{...},...}}`
  /// The `data` field is a JSON-encoded string containing the actual payload
  /// (e.g. `{"type":"new_message","message":{...}}`).
  ///
  /// We parse it and forward the inner payload to the messages stream so that
  /// consumers (ChatMessageListenerService) can process it directly without
  /// knowing about the stream_data wrapper.
  void _handleStreamData(Map<String, dynamic> envelope) {
    final sd = envelope['stream_data'] as Map<String, dynamic>?;
    if (sd == null) {
      _messageController.add(envelope);
      return;
    }

    final dataStr = sd['data'] as String?;
    if (dataStr == null || dataStr.isEmpty) {
      _messageController.add(envelope);
      return;
    }

    try {
      final inner = jsonDecode(dataStr);
      if (inner is Map<String, dynamic>) {
        _messageController.add(inner);
      } else {
        _messageController.add(<String, dynamic>{'data': inner});
      }
    } catch (_) {
      // Not valid JSON — forward raw
      _messageController.add(sd);
    }
  }

  /// Unwrap a `notification` envelope.
  ///
  /// The backend sends:
  /// ```json
  /// {"type":"notification","notification":{"notifications":[
  ///   {"subject":"chat_message","content":{"type":"new_message","message":{...}},...}
  /// ]}}
  /// ```
  ///
  /// Each notification item's `content` field contains the actual chat payload
  /// (e.g. `{"type":"new_message",...}` or `{"type":"typing_indicator",...}`).
  /// We extract and forward each one so that ChatMessageListenerService can
  /// process them directly.
  void _handleNotification(Map<String, dynamic> envelope) {
    final notif = envelope['notification'] as Map<String, dynamic>?;
    if (notif == null) {
      _messageController.add(envelope);
      return;
    }

    final items = notif['notifications'] as List?;
    if (items == null || items.isEmpty) {
      _messageController.add(envelope);
      return;
    }

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final content = item['content'];
      if (content is Map<String, dynamic> && content.containsKey('type')) {
        // Add 'via' marker so listeners know this came through notifications
        // (used for notification display decisions).
        content['via'] = 'notification';
        _messageController.add(content);
      } else if (content is String && content.isNotEmpty) {
        // Content might be a JSON string in some cases.
        try {
          final parsed = jsonDecode(content);
          if (parsed is Map<String, dynamic>) {
            parsed['via'] = 'notification';
            _messageController.add(parsed);
          }
        } catch (_) {
          // Not parseable — forward the whole item
          _messageController.add(item);
        }
      } else {
        _messageController.add(item);
      }
    }
  }

  void _handleMatchData(Map<String, dynamic> envelope) {
    final md = envelope['match_data'] as Map<String, dynamic>?;
    if (md == null) return;

    final rawData = md['data'];
    Uint8List bytes;
    if (rawData is String && rawData.isNotEmpty) {
      bytes = base64Decode(rawData);
    } else if (rawData is List) {
      bytes = Uint8List.fromList(rawData.cast<int>());
    } else {
      bytes = Uint8List(0);
    }

    _matchDataController.add(KalpixMatchData(
      matchId: md['match_id'] as String? ?? '',
      opCode: (md['op_code'] as num?)?.toInt() ?? 0,
      data: bytes,
    ));
  }

  void _handleMatchPresence(Map<String, dynamic> envelope) {
    final mp = envelope['match_presence_event'] as Map<String, dynamic>?;
    if (mp == null) return;

    _matchPresenceController.add(KalpixMatchPresenceEvent(
      matchId: mp['match_id'] as String? ?? '',
      joins: _parsePresences(mp['joins']),
      leaves: _parsePresences(mp['leaves']),
    ));
  }

  static List<KalpixUserPresence> _parsePresences(dynamic list) {
    if (list is! List) return [];
    return list
        .cast<Map<String, dynamic>>()
        .map((p) => KalpixUserPresence(
              userId: p['user_id'] as String? ?? '',
              sessionId: p['session_id'] as String? ?? '',
              username: p['username'] as String? ?? '',
            ))
        .toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> envelope) {
    _channel!.sink.add(jsonEncode(envelope));
  }

  void _assertConnected() {
    if (!_connected || _channel == null) {
      throw const KalpixSocketException();
    }
  }

  String _nextCid() => (++_cidCounter).toString();

  void _failPending(String reason) {
    for (final completer in _pendingRequests.values) {
      completer.completeError(KalpixSocketException(message: reason));
    }
    _pendingRequests.clear();
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _matchDataController.close();
    _matchPresenceController.close();
  }
}
