import '../core/http_client.dart';
import '../core/kalpix_session.dart';

/// Avatar API — character catalog, user avatar management.
class AvatarApi {
  final KalpixHttpClient _http;

  AvatarApi({required KalpixHttpClient http}) : _http = http;

  Future<Map<String, dynamic>> getCharacterCatalog(KalpixSession session) async {
    return _http.callAuthenticated('avatar/get_character_catalog', {}, session);
  }

  Future<Map<String, dynamic>> listAvatars(KalpixSession session) async {
    return _http.callAuthenticated('avatar/list_avatars', {}, session);
  }
}
