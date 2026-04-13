import '../core/http_client.dart';

/// Social API — profiles, followers, media.
class SocialApi {
  final KalpixHttpClient _http;

  SocialApi({required KalpixHttpClient http}) : _http = http;

  Future<Map<String, dynamic>> searchUsers(String query, {int limit = 20}) async {
    return _http.call('social/search_users', {'query': query, 'limit': limit});
  }

  Future<Map<String, dynamic>> getUserProfile({String? userId}) async {
    return _http.call(
      'social/get_profile_info',
      {if (userId != null) 'userId': userId},
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    return _http.call('social/update_profile', {
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
  }

  Future<void> sendFollowRequest(String targetUserId) async {
    await _http.call('social/send_follow_request', {'targetUserId': targetUserId});
  }

  Future<void> unfollow(String targetUserId) async {
    await _http.call('social/unfollow', {'targetUserId': targetUserId});
  }

  Future<Map<String, dynamic>> getReceivedFollowRequests({String? cursor}) async {
    return _http.call(
      'social/get_received_follow_requests',
      {if (cursor != null) 'cursor': cursor},
    );
  }

  Future<Map<String, dynamic>> getSentFollowRequests({String? cursor}) async {
    return _http.call(
      'social/get_sent_follow_requests',
      {if (cursor != null) 'cursor': cursor},
    );
  }

  Future<void> acceptFollowRequest(String requesterId) async {
    await _http.call('social/accept_follow_request', {'requesterId': requesterId});
  }

  Future<void> rejectFollowRequest(String requesterId) async {
    await _http.call('social/reject_follow_request', {'requesterId': requesterId});
  }

  Future<void> cancelFollowRequest(String targetUserId) async {
    await _http.call('social/cancel_follow_request', {'targetUserId': targetUserId});
  }

  Future<Map<String, dynamic>> uploadMedia({required String mediaType, required String base64Data}) async {
    return _http.call('social/upload_media', {
      'mediaType': mediaType,
      'data': base64Data,
    });
  }
}
