import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// IO platforms (mobile/desktop): use [IOWebSocketChannel] so `dart:io` sends
/// protocol-level ping frames every [pingInterval] and tears down a half-open
/// socket when a pong is missing — surfacing the drop via the channel's
/// `onDone` in ~[pingInterval], with no server support required.
WebSocketChannel connectWebSocket(Uri uri, {Duration? pingInterval}) =>
    IOWebSocketChannel.connect(uri, pingInterval: pingInterval);
