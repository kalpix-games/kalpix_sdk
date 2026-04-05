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
/// Matches the cid-based correlation the backend uses for request/response
/// matching over a single WebSocket connection.
class KalpixSocketClient {
  final KalpixConfig config;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _matchDataController = StreamController<KalpixMatchData>.broadcast();
  final _pendingRequests = <String, Completer<Map<String, dynamic>>>{};

  int _cidCounter = 0;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream of real-time match data payloads.
  Stream<KalpixMatchData> get onMatchData => _matchDataController.stream;

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
      onTimeout: () => throw const KalpixSocketException(message: 'WebSocket connection timed out'),
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

    _channel!.sink.add(jsonEncode({
      'cid': cid,
      'match_join': {'match_id': matchId},
    }));

    final result = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingRequests.remove(cid);
        throw KalpixSocketException(message: 'joinMatch "$matchId" timed out');
      },
    );
    return KalpixMatch.fromMap(result['match'] as Map<String, dynamic>? ?? result);
  }

  /// Leave a real-time match.
  Future<void> leaveMatch(String matchId) async {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'match_leave': {'match_id': matchId},
    }));
  }

  /// Send binary/JSON data to a match with a given op-code.
  void sendMatchData({
    required String matchId,
    required int opCode,
    required Uint8List data,
  }) {
    _assertConnected();
    _channel!.sink.add(jsonEncode({
      'match_data_send': {
        'match_id': matchId,
        'op_code': opCode,
        'data': base64Encode(data),
      },
    }));
  }

  /// Send an RPC call over the WebSocket and await the correlated response.
  Future<Map<String, dynamic>> rpc(String functionId, Map<String, dynamic> payload) async {
    _assertConnected();

    final cid = _nextCid();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cid] = completer;

    final envelope = {
      'type': 'rpc',
      'cid': cid,
      'rpc': {
        'id': functionId,
        'payload': jsonEncode(payload),
      },
    };

    _channel!.sink.add(jsonEncode(envelope));

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(cid);
        throw KalpixSocketException(message: 'RPC "$functionId" timed out');
      },
    );
  }

  void _handleIncoming(String raw) {
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    // Correlated RPC response
    final cid = envelope['cid'] as String?;
    if (cid != null && _pendingRequests.containsKey(cid)) {
      final completer = _pendingRequests.remove(cid)!;

      final rpcField = envelope['rpc'] as Map<String, dynamic>?;
      if (rpcField != null) {
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
            message: rpcResponse.errorMessage.isNotEmpty ? rpcResponse.errorMessage : 'RPC error',
          ));
        } else {
          completer.complete(rpcResponse.formattedData);
        }
      } else if (envelope['error'] != null) {
        final err = envelope['error'] as Map<String, dynamic>;
        completer.completeError(KalpixException(
          errorCode: err['code'] as int? ?? KalpixException.internalError,
          message: err['message'] as String? ?? 'Unknown error',
        ));
      } else {
        completer.complete({});
      }
      return;
    }

    // Real-time match data push from server
    if (envelope.containsKey('match_data')) {
      final md = envelope['match_data'] as Map<String, dynamic>;
      final rawData = md['data'] as String? ?? '';
      final bytes = rawData.isNotEmpty ? base64Decode(rawData) : Uint8List(0);
      _matchDataController.add(KalpixMatchData(
        matchId: md['match_id'] as String? ?? '',
        opCode: (md['op_code'] as num?)?.toInt() ?? 0,
        data: bytes,
      ));
      return;
    }

    // Broadcast push (chat message, notification, etc.)
    _messageController.add(envelope);
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
  }
}
