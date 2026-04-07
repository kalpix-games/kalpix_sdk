import 'dart:convert';
import 'dart:typed_data';

/// Represents an active real-time match on the Kalpix backend.
///
/// Returned by [KalpixClient.joinMatch]. The server responds with a
/// `match_joined` envelope containing match_id, presences, label, size, etc.
class KalpixMatch {
  /// The unique identifier for this match.
  final String matchId;

  /// Whether this is a server-authoritative match.
  final bool authoritative;

  /// Optional label attached to the match (e.g. game mode name).
  final String? label;

  /// Number of players currently in the match.
  final int size;

  /// Server tick rate for the match.
  final int tickRate;

  /// Current presences in the match.
  final List<KalpixUserPresence> presences;

  /// The current user's own presence in the match.
  final KalpixUserPresence? self;

  /// Creates a [KalpixMatch].
  const KalpixMatch({
    required this.matchId,
    this.authoritative = false,
    this.label,
    required this.size,
    this.tickRate = 0,
    this.presences = const [],
    this.self,
  });

  /// Deserialises a [KalpixMatch] from a `match_joined` server response.
  factory KalpixMatch.fromMap(Map<String, dynamic> map) {
    final presencesList = (map['presences'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map((p) => KalpixUserPresence.fromMap(p))
            .toList() ??
        [];

    final selfMap = map['self'] as Map<String, dynamic>?;

    return KalpixMatch(
      matchId: map['match_id'] as String? ?? map['matchId'] as String? ?? '',
      authoritative: map['authoritative'] as bool? ?? false,
      label: map['label'] as String?,
      size: (map['size'] as num?)?.toInt() ?? 0,
      tickRate: (map['tick_rate'] as num?)?.toInt() ?? 0,
      presences: presencesList,
      self: selfMap != null ? KalpixUserPresence.fromMap(selfMap) : null,
    );
  }
}

/// A single data packet received from the server during an active real-time
/// match.
///
/// Listen to [KalpixClient.onMatchData] to receive these events.
class KalpixMatchData {
  /// The ID of the match this data belongs to.
  final String matchId;

  /// Application-defined operation code that identifies the message type.
  final int opCode;

  /// Raw binary payload sent by the server.
  final Uint8List data;

  /// Creates a [KalpixMatchData] event.
  KalpixMatchData({
    required this.matchId,
    required this.opCode,
    required this.data,
  });

  /// Decodes [data] as a UTF-8 JSON object.
  ///
  /// Returns an empty map if the data is not valid JSON.
  Map<String, dynamic> decodeJson() {
    try {
      return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

/// Represents a user's presence in a match.
class KalpixUserPresence {
  final String userId;
  final String sessionId;
  final String username;
  final String status;

  const KalpixUserPresence({
    required this.userId,
    required this.sessionId,
    required this.username,
    this.status = '',
  });

  factory KalpixUserPresence.fromMap(Map<String, dynamic> map) {
    return KalpixUserPresence(
      userId: map['user_id'] as String? ?? '',
      sessionId: map['session_id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      status: map['status'] as String? ?? '',
    );
  }
}

/// Event emitted when players join or leave a match.
class KalpixMatchPresenceEvent {
  final String matchId;
  final List<KalpixUserPresence> joins;
  final List<KalpixUserPresence> leaves;

  const KalpixMatchPresenceEvent({
    required this.matchId,
    this.joins = const [],
    this.leaves = const [],
  });
}
