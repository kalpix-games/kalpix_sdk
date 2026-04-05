# kalpix_sdk

[![pub.dev](https://img.shields.io/pub/v/kalpix_sdk.svg)](https://pub.dev/packages/kalpix_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Official Flutter SDK for the **Kalpix** backend. Provides typed, async APIs for:

- **Auth** — email/password, Google/Firebase, device (guest) login, OTP, password reset
- **Chat** — DM channels, messages, reactions, pins, mute/archive, typing indicators
- **Social** — profiles, follow graph, user search, media upload
- **Store** — item catalog, cart, idempotent purchases, transaction history
- **Game** — catalog, real-time match creation, matchmaking, bot support
- **Avatar** — character catalog and user avatar management

All network calls go through a single `KalpixClient` instance backed by HTTP (REST) and WebSocket connections. No gRPC dependency.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  kalpix_sdk: ^0.1.0
```

Then run:

```sh
flutter pub get
```

---

## Quick Start

### 1. Create a client

```dart
import 'package:kalpix_sdk/kalpix_sdk.dart';

final client = KalpixClient(
  config: KalpixConfig(
    host: 'api.yourdomain.com',
    port: 443,
    ssl: true,
  ),
);
```

Or use the production preset (targets `api.kalpixsoftware.com`):

```dart
final client = KalpixClient.production();
```

### 2. Restore a saved session on startup

```dart
final session = await client.restoreSession();
if (session != null) {
  print('Logged in as ${session.username}');
}
```

### 3. Authenticate

```dart
// Email / password
final session = await client.auth.loginEmail(
  email: 'user@example.com',
  password: 's3cr3t',
);
client.setSession(session);

// Google / Firebase
final session = await client.auth.loginFirebase(idToken: firebaseIdToken);
client.setSession(session);

// Guest (device login)
final session = await client.auth.loginDevice(deviceId: 'unique-device-id');
client.setSession(session);
```

### 4. Connect the WebSocket

The WebSocket is used for real-time chat pushes and game match events. Connect after setting a session:

```dart
await client.connectSocket();
```

Listen to all incoming push messages:

```dart
client.onMessage.listen((Map<String, dynamic> envelope) {
  // envelope contains chat messages, presence updates, etc.
  print(envelope);
});
```

### 5. Use the typed APIs

All domain APIs are accessed via properties on `KalpixClient`. Every method that requires authentication takes the current `KalpixSession`:

```dart
final session = client.session!;

// --- Chat ---
// Open or reuse a DM channel
final channel = await client.chat.createOrGetDmChannel(session, 'other-user-id');
final channelId = channel['channelId'] as String;

// Join the real-time stream (required to receive push messages for this channel)
await client.chat.joinStream(channelId);

// Send a message
await client.chat.sendMessage(session, channelId: channelId, content: 'Hello!');

// React to a message
await client.chat.addReaction(session,
  channelId: channelId,
  messageId: 'msg-id',
  emoji: '👍',
);

// --- Social ---
final profile = await client.social.getUserProfile(session);
await client.social.sendFollowRequest(session, 'target-user-id');

// --- Store ---
final items = await client.store.getItems(session);
await client.store.addToCart(session, itemId: 'item-id', quantity: 1);
await client.store.confirmPurchase(session,
  purchaseToken: 'google-play-token',
  requestId: 'unique-idempotency-key',  // prevents double-charges
);

// --- Game ---
final catalog = await client.game.getCatalog(session);
final match = await client.game.createTeroMatch(session, {'gameMode': 'classic'});

// --- Avatar ---
final avatars = await client.avatar.listAvatars(session);
```

### 6. Real-time match data (games)

```dart
// Join a match over WebSocket
final match = await client.joinMatch(matchId);

// Listen for game state updates
client.onMatchData.listen((KalpixMatchData data) {
  final payload = data.decodeJson();
  print('op=${data.opCode} data=$payload');
});

// Send a game action
import 'dart:convert';
import 'dart:typed_data';

client.sendMatchData(
  matchId: match.matchId,
  opCode: 1,
  data: Uint8List.fromList(utf8.encode(jsonEncode({'action': 'play_card', 'cardId': 42}))),
);

// Leave when done
await client.leaveMatch(match.matchId);
```

### 7. Logout

```dart
await client.logout();
// Disconnects WebSocket and clears stored session
```

---

## Error Handling

All SDK methods throw `KalpixException` on failure. Use the typed helpers to branch:

```dart
try {
  await client.auth.loginEmail(email: email, password: password);
} on KalpixException catch (e) {
  if (e.isAuthError)        print('Wrong credentials');
  if (e.isRateLimit)        print('Too many attempts, slow down');
  if (e.isValidation)       print('Invalid input: ${e.message}');
  if (e.isInsufficientFunds) print('Not enough coins');
  print('Code ${e.errorCode}: ${e.message}');
} on KalpixNetworkException catch (e) {
  print('Network error: ${e.message}');
} on KalpixSocketException catch (e) {
  print('WebSocket not connected: ${e.message}');
}
```

| Code | Constant | Meaning |
|------|----------|---------|
| 1000 | `KalpixException.validation` | Invalid input |
| 1001 | `KalpixException.authentication` | Bad credentials / session expired |
| 1002 | `KalpixException.authorization` | Forbidden |
| 1003 | `KalpixException.notFound` | Resource not found |
| 1004 | `KalpixException.alreadyExists` | Duplicate resource |
| 1005 | `KalpixException.internalError` | Server error |
| 1007 | `KalpixException.rateLimit` | Rate limited |
| 1009 | `KalpixException.expired` | Token/offer expired |
| 1010 | `KalpixException.insufficientFunds` | Not enough balance |

---

## Session Persistence

The SDK automatically persists the session to `SharedPreferences` after every login. On app startup call `restoreSession()` to skip the login screen if a valid session exists:

```dart
@override
void initState() {
  super.initState();
  _initSession();
}

Future<void> _initSession() async {
  final session = await client.restoreSession();
  if (session != null && !session.isExpired) {
    // User is already logged in
    await client.connectSocket();
    Navigator.pushReplacementNamed(context, '/home');
  }
}
```

---

## Custom RPC Calls

For endpoints not covered by the typed APIs, use the escape hatches:

```dart
// Authenticated call (Bearer token sent automatically)
final data = await client.callRpc('my/custom_endpoint', {'key': 'value'});

// Public call (no auth header)
final data = await client.callPublicRpc('my/public_endpoint', {'key': 'value'});

// Over WebSocket
final data = await client.callSocketRpc('my/socket_endpoint', {'key': 'value'});
```

---

## API Reference

Full API documentation is available at [pub.dev/documentation/kalpix_sdk](https://pub.dev/documentation/kalpix_sdk/latest/).

---

## License

MIT — see [LICENSE](LICENSE).
