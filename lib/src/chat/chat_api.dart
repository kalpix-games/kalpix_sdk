import '../core/http_client.dart';
import '../core/kalpix_session.dart';
import '../core/socket_client.dart';

/// Chat API — DM channels, messages, reactions, moderation.
///
/// Most message operations use HTTP (authenticated RPC).
/// Stream join/leave uses the WebSocket ([KalpixSocketClient]).
class ChatApi {
  final KalpixHttpClient _http;
  final KalpixSocketClient _socket;

  ChatApi({required KalpixHttpClient http, required KalpixSocketClient socket})
    : _http = http,
      _socket = socket;

  // ── Channels ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createOrGetDmChannel(KalpixSession session, String recipientId) async {
    return _http.callAuthenticated('chat/create_or_get_dm_channel', {'recipientId': recipientId}, session);
  }

  Future<Map<String, dynamic>> getConversationsByIds(KalpixSession session, List<String> channelIds) async {
    return _http.callAuthenticated('chat/get_conversations_by_ids', {'channelIds': channelIds}, session);
  }

  Future<Map<String, dynamic>> getCatalog(KalpixSession session, {String? cursor, int limit = 20}) async {
    return _http.callAuthenticated('chat/get_catalog', {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    }, session);
  }

  /// Join a channel stream over WebSocket (required before receiving push messages).
  Future<Map<String, dynamic>> joinStream(String channelId) async {
    return _socket.rpc('chat/join_stream', {'channelId': channelId});
  }

  /// Leave a channel stream over WebSocket.
  Future<Map<String, dynamic>> leaveStream(String channelId) async {
    return _socket.rpc('chat/leave_stream', {'channelId': channelId});
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendMessage(
    KalpixSession session, {
    required String channelId,
    required String content,
    List<Map<String, dynamic>>? attachments,
    String? replyToMessageId,
  }) async {
    return _http.callAuthenticated('chat/send_message', {
      'channelId': channelId,
      'content': content,
      if (attachments != null) 'attachments': attachments,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    }, session);
  }

  Future<Map<String, dynamic>> editMessage(
    KalpixSession session, {
    required String channelId,
    required String messageId,
    required String content,
  }) async {
    return _http.callAuthenticated('chat/edit_message', {
      'channelId': channelId,
      'messageId': messageId,
      'content': content,
    }, session);
  }

  Future<void> deleteMessage(KalpixSession session, {required String channelId, required String messageId}) async {
    await _http.callAuthenticated('chat/delete_message', {'channelId': channelId, 'messageId': messageId}, session);
  }

  Future<Map<String, dynamic>> forwardMessage(
    KalpixSession session, {
    required String sourceChannelId,
    required String messageId,
    required String targetChannelId,
  }) async {
    return _http.callAuthenticated('chat/forward_message', {
      'sourceChannelId': sourceChannelId,
      'messageId': messageId,
      'targetChannelId': targetChannelId,
    }, session);
  }

  // ── Receipts & Status ──────────────────────────────────────────────────────

  Future<void> markDelivered(KalpixSession session, {required String channelId, required String messageId}) async {
    await _http.callAuthenticated('chat/mark_delivered', {'channelId': channelId, 'messageId': messageId}, session);
  }

  Future<void> markMessagesRead(KalpixSession session, {required String channelId, required String upToMessageId}) async {
    await _http.callAuthenticated('chat/mark_messages_read', {'channelId': channelId, 'upToMessageId': upToMessageId}, session);
  }

  Future<Map<String, dynamic>> syncAndDeliver(KalpixSession session, Map<String, dynamic> payload) async {
    return _http.callAuthenticated('chat/sync_and_deliver', payload, session);
  }

  // ── Reactions ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addReaction(
    KalpixSession session, {
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    return _http.callAuthenticated('chat/add_reaction', {
      'channelId': channelId,
      'messageId': messageId,
      'emoji': emoji,
    }, session);
  }

  Future<Map<String, dynamic>> removeReaction(
    KalpixSession session, {
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    return _http.callAuthenticated('chat/remove_reaction', {
      'channelId': channelId,
      'messageId': messageId,
      'emoji': emoji,
    }, session);
  }

  // ── Pins ──────────────────────────────────────────────────────────────────

  Future<void> pinMessage(KalpixSession session, {required String channelId, required String messageId}) async {
    await _http.callAuthenticated('chat/pin_message', {'channelId': channelId, 'messageId': messageId}, session);
  }

  Future<void> unpinMessage(KalpixSession session, {required String channelId, required String messageId}) async {
    await _http.callAuthenticated('chat/unpin_message', {'channelId': channelId, 'messageId': messageId}, session);
  }

  // ── Channel settings ──────────────────────────────────────────────────────

  Future<void> muteChannel(KalpixSession session, {required String channelId, int? muteUntil}) async {
    await _http.callAuthenticated('chat/mute_channel', {
      'channelId': channelId,
      if (muteUntil != null) 'muteUntil': muteUntil,
    }, session);
  }

  Future<void> unmuteChannel(KalpixSession session, String channelId) async {
    await _http.callAuthenticated('chat/unmute_channel', {'channelId': channelId}, session);
  }

  Future<void> archiveChannel(KalpixSession session, String channelId) async {
    await _http.callAuthenticated('chat/archive_channel', {'channelId': channelId}, session);
  }

  Future<void> unarchiveChannel(KalpixSession session, String channelId) async {
    await _http.callAuthenticated('chat/unarchive_channel', {'channelId': channelId}, session);
  }

  Future<void> clearHistory(KalpixSession session, String channelId) async {
    await _http.callAuthenticated('chat/clear_chat', {'channelId': channelId}, session);
  }

  // ── Moderation ────────────────────────────────────────────────────────────

  Future<void> acceptDmRequest(KalpixSession session, String channelId) async {
    await _http.callAuthenticated('chat/accept_dm_request', {'channelId': channelId}, session);
  }

  Future<void> deleteDmRequest(KalpixSession session, String channelId) async {
    await _http.callAuthenticated('chat/delete_dm_request', {'channelId': channelId}, session);
  }

  Future<void> blockUser(KalpixSession session, String targetUserId) async {
    await _http.callAuthenticated('chat/block_user', {'targetUserId': targetUserId}, session);
  }

  Future<void> unblockUser(KalpixSession session, String targetUserId) async {
    await _http.callAuthenticated('chat/unblock_user', {'targetUserId': targetUserId}, session);
  }

  Future<void> reportUser(KalpixSession session, {required String targetUserId, required String reason}) async {
    await _http.callAuthenticated('chat/report_user', {'targetUserId': targetUserId, 'reason': reason}, session);
  }

  Future<void> reportMessage(
    KalpixSession session, {
    required String channelId,
    required String messageId,
    required String reason,
  }) async {
    await _http.callAuthenticated('chat/report_message', {
      'channelId': channelId,
      'messageId': messageId,
      'reason': reason,
    }, session);
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  Future<void> sendTypingIndicator(KalpixSession session, String channelId) async {
    await _http.callAuthenticated('chat/send_typing_indicator', {'channelId': channelId}, session);
  }
}
