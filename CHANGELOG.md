## 0.5.1

- **Connection resilience.** `connect()` now awaits the WebSocket handshake so
  connect-time failures (e.g. host lookup when offline) are caught instead of
  surfacing as uncaught async errors or polluting the message stream. Overlapping
  connects are guarded.
- **Half-open drop detection.** On mobile/desktop the socket connects with a
  `pingInterval` (10s) so `dart:io` sends protocol-level ping frames and closes a
  dead/half-open socket within ~10s — triggering the existing auto-reconnect. A
  conditional import keeps web/desktop building.
- Added `onConnectionStateChanged` (`Stream<bool>`) on `KalpixClient` —
  emits `true` on connect, `false` on drop.

## 0.5.0

- **Leaderboards are now Glicko-2 skill ratings.** Removed the legacy score-based
  period model.
- **BREAKING:** `GameApi.getLeaderboard`, `getLeaderboardAroundPlayer`, and
  `getFriendsLeaderboard` no longer take a `period` argument — each game has a
  single rating board, resolved server-side from `gameId`.
- Added `GameApi.getRating(gameId, {userId})` for a player's Glicko-2 rating
  (rating, deviation, provisional/ranked flags, peak, leaderboard rank).
- `KalpixClient.local()` now defaults to `192.168.31.243:7350`.

## 0.4.2

- Initial public release.
- `KalpixClient` — single entry point with `production()` factory.
- `AuthApi` — email, Firebase/Google, device login; OTP; password reset; account deletion.
- `ChatApi` — DM channels, messages, reactions, pins, mute/archive, typing indicators, moderation.
- `SocialApi` — user profiles, follow graph, user search, media upload.
- `StoreApi` — item catalog, cart, idempotent purchases, transaction history.
- `GameApi` — game catalog, Tero match creation, matchmaking, bot support.
- `AvatarApi` — character catalog, user avatar listing.
- `KalpixSocketClient` — cid-correlated WebSocket with real-time match support (`joinMatch`, `leaveMatch`, `sendMatchData`, `onMatchData` stream).
- `KalpixSession` — session model with expiry checks and `SharedPreferences` persistence.
- `KalpixException` — typed error codes 1000–1010 with convenience getters.
