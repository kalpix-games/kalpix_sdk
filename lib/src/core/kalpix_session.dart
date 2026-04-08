/// An authenticated session returned by the Kalpix backend after a successful
/// login. Holds JWT tokens and their expiry times.
///
/// Sessions are persisted automatically by [KalpixClient] via
/// [SessionStore] and can be restored on startup with
/// `KalpixClient.restoreSession()`.
class KalpixSession {
  /// The short-lived JWT bearer token used in `Authorization` headers.
  final String token;

  /// The long-lived refresh token used to obtain a new [token] when it expires.
  final String refreshToken;

  /// The authenticated user's ID.
  final String userId;

  /// The authenticated user's username.
  final String username;

  /// When [token] expires.
  final DateTime expiresAt;

  /// When [refreshToken] expires.
  final DateTime refreshExpiresAt;

  /// Creates a [KalpixSession].
  const KalpixSession({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.username,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });

  /// Returns `true` if [token] has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Returns `true` if [refreshToken] has expired.
  bool get isRefreshExpired => DateTime.now().isAfter(refreshExpiresAt);

  /// Deserialises a session from a map (e.g. stored JSON or an API response).
  ///
  /// Accepts both Go backend camelCase keys (`sessionToken`, `expiresAt`) and
  /// legacy/persisted snake_case keys (`token`, `expires_at`).
  factory KalpixSession.fromMap(Map<String, dynamic> map) {
    return KalpixSession(
      token: map['sessionToken'] as String? ?? map['token'] as String? ?? '',
      refreshToken: map['refreshToken'] as String? ?? map['refresh_token'] as String? ?? '',
      userId: map['userId'] as String? ?? map['user_id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      expiresAt: _parseTime(map['expiresAt'] ?? map['expires_at']),
      refreshExpiresAt: _parseTime(map['refreshExpiresAt'] ?? map['refresh_expires_at']),
    );
  }

  /// Serialises the session to a map suitable for JSON storage.
  ///
  /// Uses the same camelCase keys the Go backend sends so that
  /// `fromMap(toMap())` round-trips correctly. Timestamps are persisted as
  /// Unix **seconds** (matching the backend convention).
  Map<String, dynamic> toMap() => {
    'sessionToken': token,
    'refreshToken': refreshToken,
    'userId': userId,
    'username': username,
    'expiresAt': expiresAt.millisecondsSinceEpoch ~/ 1000,
    'refreshExpiresAt': refreshExpiresAt.millisecondsSinceEpoch ~/ 1000,
  };

  /// Returns a copy of this session with the given fields replaced.
  KalpixSession copyWith({
    String? token,
    String? refreshToken,
    String? userId,
    String? username,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
  }) {
    return KalpixSession(
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
    );
  }

  /// Parse a timestamp that may be Unix seconds (from Go backend), Unix
  /// milliseconds (from older persisted sessions), or an ISO-8601 string.
  ///
  /// Heuristic: values below 1e12 (~Nov 2001 in ms, but ~33,658 AD in seconds)
  /// are treated as seconds; values >= 1e12 are treated as milliseconds.
  static DateTime _parseTime(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(hours: 1));
    if (value is int) {
      if (value < 1000000000000) {
        // Unix seconds (Go backend sends this)
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      // Unix milliseconds (legacy persisted sessions)
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.now().add(const Duration(hours: 1));
    }
    return DateTime.now().add(const Duration(hours: 1));
  }
}
