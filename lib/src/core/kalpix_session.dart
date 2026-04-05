/// Represents an authenticated session with the Kalpix backend.
class KalpixSession {
  final String token;
  final String refreshToken;
  final String userId;
  final String username;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;

  const KalpixSession({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.username,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isRefreshExpired => DateTime.now().isAfter(refreshExpiresAt);

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

  Map<String, dynamic> toMap() => {
    'token': token,
    'refresh_token': refreshToken,
    'user_id': userId,
    'username': username,
    'expires_at': expiresAt.millisecondsSinceEpoch,
    'refresh_expires_at': refreshExpiresAt.millisecondsSinceEpoch,
  };

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
