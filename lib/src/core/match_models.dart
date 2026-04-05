import 'dart:convert';
import 'dart:typed_data';

/// Represents an active real-time match on the Kalpix backend.
///
/// Returned by [KalpixClient.joinMatch].
class KalpixMatch {
  /// The unique identifier for this match.
  final String matchId;

  /// Whether this is a server-authoritative match.
  final bool authoritative;

  /// Optional label attached to the match (e.g. game mode name).
  final String? label;

  /// Number of players currently in the match.
  final int size;

  /// Creates a [KalpixMatch].
  const KalpixMatch({
    required this.matchId,
    required this.authoritative,
    this.label,
    required this.size,
  });

  /// Deserialises a [KalpixMatch] from a server response map.
  factory KalpixMatch.fromMap(Map<String, dynamic> map) {
    return KalpixMatch(
      matchId: map['match_id'] as String? ?? map['matchId'] as String? ?? '',
      authoritative: map['authoritative'] as bool? ?? false,
      label: map['label'] as String?,
      size: (map['size'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A single data packet received from the server during an active real-time
/// match.
///
/// Listen to [KalpixClient.onMatchData] to receive these events.
///
/// ```dart
/// client.onMatchData.listen((KalpixMatchData data) {
///   final payload = data.decodeJson();
///   switch (data.opCode) {
///     case 1: handleGameAction(payload);
///     case 2: handleLobbyState(payload);
///   }
/// });
/// ```
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
