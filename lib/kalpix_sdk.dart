/// Kalpix SDK — official Flutter SDK for the Kalpix backend.
///
/// Import this single file to access all SDK functionality:
/// ```dart
/// import 'package:kalpix_sdk/kalpix_sdk.dart';
/// ```
library kalpix_sdk;

// Core
export 'src/core/kalpix_client.dart';
export 'src/core/kalpix_config.dart';
export 'src/core/kalpix_session.dart';
export 'src/core/kalpix_exception.dart';
export 'src/core/match_models.dart';
export 'src/core/socket_client.dart' show KalpixSocketClient;

// Domain APIs (re-exported so callers can type-hint them)
export 'src/auth/auth_api.dart';
export 'src/chat/chat_api.dart';
export 'src/social/social_api.dart';
export 'src/store/store_api.dart';
export 'src/game/game_api.dart';
export 'src/avatar/avatar_api.dart';
