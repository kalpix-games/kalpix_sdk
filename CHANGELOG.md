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
