import '../core/http_client.dart';

/// Game API — catalog, match creation, matchmaking, leaderboards, stats.
class GameApi {
  final KalpixHttpClient _http;

  GameApi({required KalpixHttpClient http}) : _http = http;

  /// Get full game catalog.
  Future<Map<String, dynamic>> getCatalog() async {
    return _http.call('game/get_catalog', {});
  }

  /// Create a private Tero match.
  Future<Map<String, dynamic>> createTeroMatch(Map<String, dynamic> options) async {
    return _http.call('create_tero_match', options);
  }

  /// Add a bot to a private match lobby.
  Future<Map<String, dynamic>> addBotToMatch({required String matchId, String? botDifficulty}) async {
    return _http.call('add_bot_to_match', {
      'matchId': matchId,
      if (botDifficulty != null) 'difficulty': botDifficulty,
    });
  }

  /// Validate a match ID before joining (e.g. when entering a match code).
  Future<Map<String, dynamic>> validateMatch({required String matchId}) async {
    return _http.call('validate_match', {'matchId': matchId});
  }

  /// Find or create a random match via matchmaking.
  Future<Map<String, dynamic>> findOrCreateRandomMatch(Map<String, dynamic> options) async {
    return _http.call('find_or_create_random_match', options);
  }

  /// Get active matches for a specific game (for "Rejoin" banner).
  Future<Map<String, dynamic>> getActiveMatch({required String gameId}) async {
    return _http.call('game/get_active_match', {'gameId': gameId});
  }

  /// Get game info with mode configs for rendering the game screen.
  Future<Map<String, dynamic>> getGameInfo({required String gameId}) async {
    return _http.call('game/get_info', {'gameId': gameId});
  }

  /// Get game rules (how to play).
  Future<Map<String, dynamic>> getGameRules({required String gameId}) async {
    return _http.call('game/get_rules', {'gameId': gameId});
  }

  /// Get leaderboard entries for a game + period.
  Future<Map<String, dynamic>> getLeaderboard({
    required String gameId,
    required String period,
    int limit = 20,
    String? cursor,
  }) async {
    return _http.call('game/get_leaderboard', {
      'gameId': gameId,
      'period': period,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
  }

  /// Get leaderboard entries centered around the current player ("Find Me").
  Future<Map<String, dynamic>> getLeaderboardAroundPlayer({
    required String gameId,
    required String period,
    int limit = 10,
  }) async {
    return _http.call('game/get_leaderboard_around_player', {
      'gameId': gameId,
      'period': period,
      'limit': limit,
    });
  }

  /// Get friends-only leaderboard.
  Future<Map<String, dynamic>> getFriendsLeaderboard({
    required String gameId,
    required String period,
    int limit = 50,
  }) async {
    return _http.call('game/get_friends_leaderboard', {
      'gameId': gameId,
      'period': period,
      'limit': limit,
    });
  }

  /// List available leaderboard periods for a game.
  Future<Map<String, dynamic>> listLeaderboards({required String gameId}) async {
    return _http.call('game/list_leaderboards', {'gameId': gameId});
  }

  /// Get player stats for a game.
  ///
  /// Returns stats for the current user by default.
  /// Pass [userId] to view another player's public stats.
  Future<Map<String, dynamic>> getPlayerStats({required String gameId, String? userId}) async {
    return _http.call('game/get_stats', {
      'gameId': gameId,
      if (userId != null) 'userId': userId,
    });
  }

  /// Get match history for a game.
  Future<Map<String, dynamic>> getMatchHistory({
    required String gameId,
    int limit = 20,
    String? cursor,
  }) async {
    return _http.call('game/get_match_history', {
      'gameId': gameId,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
  }
}
