import '../core/http_client.dart';
import '../core/kalpix_session.dart';

/// Social API — profiles, followers, media.
class SocialApi {
  final KalpixHttpClient _http;

  SocialApi({required KalpixHttpClient http}) : _http = http;

  Future<Map<String, dynamic>> searchUsers(KalpixSession session, String query, {int limit = 20}) async {
    return _http.callAuthenticated('social/search_users', {'query': query, 'limit': limit}, session);
  }

  Future<Map<String, dynamic>> getUserProfile(KalpixSession session, {String? userId}) async {
    return _http.callAuthenticated(
      'social/get_profile_info',
      {if (userId != null) 'userId': userId},
      session,
    );
  }

  Future<Map<String, dynamic>> updateProfile(
    KalpixSession session, {
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    return _http.callAuthenticated('social/update_profile', {
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    }, session);
  }

  Future<void> sendFollowRequest(KalpixSession session, String targetUserId) async {
    await _http.callAuthenticated('social/send_follow_request', {'targetUserId': targetUserId}, session);
  }

  Future<void> unfollow(KalpixSession session, String targetUserId) async {
    await _http.callAuthenticated('social/unfollow', {'targetUserId': targetUserId}, session);
  }

  Future<Map<String, dynamic>> getReceivedFollowRequests(KalpixSession session, {String? cursor}) async {
    return _http.callAuthenticated(
      'social/get_received_follow_requests',
      {if (cursor != null) 'cursor': cursor},
      session,
    );
  }

  Future<Map<String, dynamic>> getSentFollowRequests(KalpixSession session, {String? cursor}) async {
    return _http.callAuthenticated(
      'social/get_sent_follow_requests',
      {if (cursor != null) 'cursor': cursor},
      session,
    );
  }

  Future<void> acceptFollowRequest(KalpixSession session, String requesterId) async {
    await _http.callAuthenticated('social/accept_follow_request', {'requesterId': requesterId}, session);
  }

  Future<void> rejectFollowRequest(KalpixSession session, String requesterId) async {
    await _http.callAuthenticated('social/reject_follow_request', {'requesterId': requesterId}, session);
  }

  Future<void> cancelFollowRequest(KalpixSession session, String targetUserId) async {
    await _http.callAuthenticated('social/cancel_follow_request', {'targetUserId': targetUserId}, session);
  }

  Future<Map<String, dynamic>> uploadMedia(KalpixSession session, {required String mediaType, required String base64Data}) async {
    return _http.callAuthenticated('social/upload_media', {
      'mediaType': mediaType,
      'data': base64Data,
    }, session);
  }
}
