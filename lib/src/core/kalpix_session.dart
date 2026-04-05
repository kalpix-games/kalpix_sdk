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
  factory KalpixSession.fromMap(Map<String, dynamic> map) {
    return KalpixSession(
      token: map['token'] as String? ?? '',
      refreshToken: map['refresh_token'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      expiresAt: _parseTime(map['expires_at']),
      refreshExpiresAt: _parseTime(map['refresh_expires_at']),
    );
  }

  /// Serialises the session to a map suitable for JSON storage.
  Map<String, dynamic> toMap() => {
    'token': token,
    'refresh_token': refreshToken,
    'user_id': userId,
    'username': username,
    'expires_at': expiresAt.millisecondsSinceEpoch,
    'refresh_expires_at': refreshExpiresAt.millisecondsSinceEpoch,
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

  static DateTime _parseTime(dynamic value) {
    if (value == null) return DateTime.now().add(const Duration(hours: 1));
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now().add(const Duration(hours: 1));
    return DateTime.now().add(const Duration(hours: 1));
  }
}
