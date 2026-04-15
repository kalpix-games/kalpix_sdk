## 0.4.1

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
