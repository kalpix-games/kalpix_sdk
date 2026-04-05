/// Kalpix SDK — official Flutter SDK for the Kalpix backend.
///
/// Import this single file to access the full SDK:
///
/// ```dart
/// import 'package:kalpix_sdk/kalpix_sdk.dart';
/// ```
///
/// ## Getting started
///
/// ```dart
/// final client = KalpixClient(
///   config: KalpixConfig(
///     host: 'api.yourdomain.com',
///     serverKey: 'your-server-key',
///   ),
/// );
///
/// // Restore a saved session (skips login if still valid)
/// final session = await client.restoreSession();
/// if (session == null) {
///   final session = await client.auth.loginEmail(email: '...', password: '...');
///   client.setSession(session);
/// }
///
/// // Connect WebSocket for real-time chat and match events
/// await client.connectSocket();
/// ```
library kalpix_sdk;

// Core
export 'src/core/kalpix_client.dart';
export 'src/core/kalpix_config.dart';
export 'src/core/kalpix_session.dart';
export 'src/core/kalpix_exception.dart';
export 'src/core/match_models.dart';
export 'src/core/socket_client.dart' show KalpixSocketClient;

// Domain APIs
export 'src/auth/auth_api.dart';
export 'src/chat/chat_api.dart';
export 'src/social/social_api.dart';
export 'src/store/store_api.dart';
export 'src/game/game_api.dart';
export 'src/avatar/avatar_api.dart';
