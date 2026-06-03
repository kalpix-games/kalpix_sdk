import 'package:web_socket_channel/web_socket_channel.dart';

/// Web: the browser manages WebSocket keepalive and [pingInterval] is not
/// configurable, so it is ignored. Kept so callers have one cross-platform
/// entry point.
WebSocketChannel connectWebSocket(Uri uri, {Duration? pingInterval}) =>
    WebSocketChannel.connect(uri);
