import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'kalpix_config.dart';
import 'kalpix_exception.dart';
import 'kalpix_session.dart';
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
  final _pendingRequests = <String, Completer<Map<String, dynamic>>>{};

  int _cidCounter = 0;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
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
  }
}
