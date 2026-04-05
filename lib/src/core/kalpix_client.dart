import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../auth/auth_api.dart';
import '../avatar/avatar_api.dart';
import '../chat/chat_api.dart';
import '../game/game_api.dart';
import '../social/social_api.dart';
import '../store/store_api.dart';
import 'http_client.dart';
import 'kalpix_config.dart';
import 'kalpix_exception.dart';
import 'kalpix_session.dart';
import 'match_models.dart';
import 'session_store.dart';
import 'socket_client.dart';

/// Main entry point for the Kalpix SDK.
///
/// Usage:
/// ```dart
/// final client = KalpixClient(
///   config: KalpixConfig(
///     host: 'api.kalpixsoftware.com',
///     serverKey: 'your-server-key',
///   ),
/// );
///
/// await client.initialize();
/// final session = await client.auth.loginEmail(email: '...', password: '...');
/// client.setSession(session);
/// await client.connectSocket();
/// ```
class KalpixClient {
  final KalpixConfig config;

  late final KalpixHttpClient _http;
  late final KalpixSocketClient _socket;
  late final SessionStore _sessionStore;

  late final AuthApi auth;
  late final SocialApi social;
  late final ChatApi chat;
  late final StoreApi store;
  late final GameApi game;
  late final AvatarApi avatar;

  KalpixSession? _session;

  /// Fired when the session changes (login, logout, refresh).
  final _sessionChangeController = StreamController<KalpixSession?>.broadcast();
  Stream<KalpixSession?> get onSessionChange => _sessionChangeController.stream;

  /// Stream of all raw push messages received over the WebSocket.
  Stream<Map<String, dynamic>> get onMessage => _socket.messages;

  /// Stream of real-time match data payloads.
  Stream<KalpixMatchData> get onMatchData => _socket.onMatchData;

  KalpixSession? get session => _session;
  bool get isAuthenticated => _session != null && !_session!.isExpired;
  bool get isSocketConnected => _socket.isConnected;

  KalpixClient({required this.config}) {
    _sessionStore = SessionStore();
    _http = KalpixHttpClient(config: config);
    _socket = KalpixSocketClient(config: config);

    auth = AuthApi(http: _http, store: _sessionStore);
    social = SocialApi(http: _http);
    chat = ChatApi(http: _http, socket: _socket);
    store = StoreApi(http: _http);
    game = GameApi(http: _http);
    avatar = AvatarApi(http: _http);
  }

  /// Convenience factory targeting the production Kalpix server.
  factory KalpixClient.production() {
    return KalpixClient(
      config: const KalpixConfig(
        host: 'api.kalpixsoftware.com',
        port: 443,
        ssl: true,
      ),
    );
  }

  /// Convenience factory targeting a local development server.
  ///
  /// Example:
  /// ```dart
  /// final client = KalpixClient.local(host: '192.168.31.243', port: 8080);
  /// ```
  factory KalpixClient.local({String host = 'localhost', int port = 8080}) {
    return KalpixClient(
      config: KalpixConfig(
        host: host,
        port: port,
        ssl: false,
      ),
    );
  }

  /// Attempt to restore a session from persistent storage.
  /// Returns the restored session or null if none exists / it has expired.
  Future<KalpixSession?> restoreSession() async {
    final saved = await _sessionStore.load();
    if (saved == null) return null;
    if (saved.isRefreshExpired) {
      await _sessionStore.clear();
      return null;
    }
    _session = saved;
    _sessionChangeController.add(_session);
    return _session;
  }

  /// Set the active session manually (e.g., after login).
  void setSession(KalpixSession session) {
    _session = session;
    _sessionChangeController.add(_session);
  }

  /// Connect the WebSocket using the current session.
  /// Must call [setSession] first.
  Future<void> connectSocket() async {
    final s = _requireSession();
    await _socket.connect(s);
  }

  /// Disconnect the WebSocket.
  Future<void> disconnectSocket() async {
    await _socket.disconnect();
  }

  /// Log out: disconnect socket, clear storage, nullify session.
  Future<void> logout() async {
    await _socket.disconnect();
    await _sessionStore.clear();
    _session = null;
    _sessionChangeController.add(null);
  }

  /// Call an arbitrary authenticated RPC (for custom endpoints not covered by the typed APIs).
  Future<Map<String, dynamic>> callRpc(String functionId, Map<String, dynamic> payload) async {
    return _http.callAuthenticated(functionId, payload, _requireSession());
  }

  /// Call a public RPC (no session required).
  Future<Map<String, dynamic>> callPublicRpc(String functionId, Map<String, dynamic> payload) async {
    return _http.callPublic(functionId, payload);
  }

  /// Call an RPC over the WebSocket connection.
  Future<Map<String, dynamic>> callSocketRpc(String functionId, Map<String, dynamic> payload) async {
    return _socket.rpc(functionId, payload);
  }

  /// Join a real-time match by match ID.
  Future<KalpixMatch> joinMatch(String matchId) async {
    return _socket.joinMatch(matchId);
  }

  /// Leave a real-time match.
  Future<void> leaveMatch(String matchId) async {
    await _socket.leaveMatch(matchId);
  }

  /// Send binary data to a match with a given op-code.
  void sendMatchData({
    required String matchId,
    required int opCode,
    required Uint8List data,
  }) {
    _socket.sendMatchData(matchId: matchId, opCode: opCode, data: data);
  }

  KalpixSession _requireSession() {
    final s = _session;
    if (s == null) throw const KalpixSessionExpiredException();
    return s;
  }

  void dispose() {
    _socket.dispose();
    _http.dispose();
    _sessionChangeController.close();
  }
}
