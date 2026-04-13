import '../core/http_client.dart';

/// Avatar API — character catalog, user avatar management.
class AvatarApi {
  final KalpixHttpClient _http;

  AvatarApi({required KalpixHttpClient http}) : _http = http;

  Future<Map<String, dynamic>> getCharacterCatalog() async {
    return _http.call('avatar/get_character_catalog', {});
  }

  Future<Map<String, dynamic>> listAvatars() async {
    return _http.call('avatar/list_avatars', {});
  }
}
