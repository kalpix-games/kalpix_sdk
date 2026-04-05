import '../core/http_client.dart';
import '../core/kalpix_session.dart';

/// Game API — catalog, match creation, matchmaking.
class GameApi {
  final KalpixHttpClient _http;

  GameApi({required KalpixHttpClient http}) : _http = http;

  Future<Map<String, dynamic>> getCatalog(KalpixSession session) async {
    return _http.callAuthenticated('game/get_catalog', {}, session);
  }

  Future<Map<String, dynamic>> createTeroMatch(KalpixSession session, Map<String, dynamic> options) async {
    return _http.callAuthenticated('create_tero_match', options, session);
  }

  Future<Map<String, dynamic>> addBotToMatch(KalpixSession session, {required String matchId, String? botDifficulty}) async {
    return _http.callAuthenticated('add_bot_to_match', {
      'matchId': matchId,
      if (botDifficulty != null) 'difficulty': botDifficulty,
    }, session);
  }

  Future<Map<String, dynamic>> validateMatch(KalpixSession session, {required String matchId}) async {
    return _http.callAuthenticated('validate_match', {'matchId': matchId}, session);
  }

  Future<Map<String, dynamic>> findOrCreateRandomMatch(KalpixSession session, Map<String, dynamic> options) async {
    return _http.callAuthenticated('find_or_create_random_match', options, session);
  }
}
