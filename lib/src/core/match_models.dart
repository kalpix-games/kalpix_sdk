import 'dart:convert';
import 'dart:typed_data';

/// Represents a real-time match.
class KalpixMatch {
  final String matchId;
  final bool authoritative;
  final String? label;
  final int size;

  const KalpixMatch({
    required this.matchId,
    required this.authoritative,
    this.label,
    required this.size,
  });

  factory KalpixMatch.fromMap(Map<String, dynamic> map) {
    return KalpixMatch(
      matchId: map['match_id'] as String? ?? map['matchId'] as String? ?? '',
      authoritative: map['authoritative'] as bool? ?? false,
      label: map['label'] as String?,
      size: (map['size'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Represents data received from a real-time match.
class KalpixMatchData {
  final String matchId;
  final int opCode;
  final Uint8List data;

  KalpixMatchData({required this.matchId, required this.opCode, required this.data});

  /// Decode data as a JSON map.
  Map<String, dynamic> decodeJson() {
    try {
      return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
