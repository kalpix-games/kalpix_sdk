import '../core/http_client.dart';
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

  Future<Map<String, dynamic>> createOrGetDmChannel(String recipientId) async {
    return _http.call('chat/create_or_get_dm_channel', {'recipientId': recipientId});
  }

  Future<Map<String, dynamic>> getConversationsByIds(List<String> channelIds) async {
    return _http.call('chat/get_conversations_by_ids', {'channelIds': channelIds});
  }

  Future<Map<String, dynamic>> getCatalog({String? cursor, int limit = 20}) async {
    return _http.call('chat/get_catalog', {
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
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

  Future<GetMessagesResult> getMessages({
    required String channelId,
    String cursor = '',
    int limit = 30,
  }) async {
    final resp = await _http.call('chat/get_messages', {
      'channelId': channelId,
      'limit': limit,
      if (cursor.isNotEmpty) 'cursor': cursor,
    });

    final rawItems = resp['items'];
    final items = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map) items.add(Map<String, dynamic>.from(it));
      }
    }

    ChannelReadState? readState;
    final rs = resp['readState'];
    if (rs is Map) {
      readState = ChannelReadState.fromJson(Map<String, dynamic>.from(rs));
    }

    return GetMessagesResult(
      items: items,
      nextCursor: (resp['nextCursor'] as String?) ?? '',
      hasMore: resp['hasMore'] == true,
      readState: readState,
    );
  }

  Future<Map<String, dynamic>> sendMessage({
    required String channelId,
    required String content,
    List<Map<String, dynamic>>? attachments,
    String? replyToMessageId,
  }) async {
    return _http.call('chat/send_message', {
      'channelId': channelId,
      'content': content,
      if (attachments != null) 'attachments': attachments,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
  }

  Future<Map<String, dynamic>> editMessage({
    required String channelId,
    required String messageId,
    required String content,
  }) async {
    return _http.call('chat/edit_message', {
      'channelId': channelId,
      'messageId': messageId,
      'content': content,
    });
  }

  Future<void> deleteMessage({required String channelId, required String messageId}) async {
    await _http.call('chat/delete_message', {'channelId': channelId, 'messageId': messageId});
  }

  Future<Map<String, dynamic>> forwardMessage({
    required String sourceChannelId,
    required String messageId,
    required String targetChannelId,
  }) async {
    return _http.call('chat/forward_message', {
      'sourceChannelId': sourceChannelId,
      'messageId': messageId,
      'targetChannelId': targetChannelId,
    });
  }

  // ── Receipts & Status ──────────────────────────────────────────────────────

  Future<void> markDelivered({required String channelId, required String messageId}) async {
    await _http.call('chat/mark_delivered', {'channelId': channelId, 'messageId': messageId});
  }

  // ── Read pointer (Telegram-style) ─────────────────────────────────────────

  Future<ChannelReadState> markRead({
    required String channelId,
    required String upToMessageId,
  }) async {
    final resp = await _http.call(
      'chat/mark_read',
      {'channelId': channelId, 'upToMessageId': upToMessageId},
    );
    return ChannelReadState.fromJson(resp);
  }

  Future<Map<String, ChannelReadState>> markAllChannelsRead(List<String> channelIds) async {
    if (channelIds.isEmpty) return const {};
    final resp = await _http.call(
      'chat/mark_messages_read',
      {'channelIds': channelIds},
    );
    final result = <String, ChannelReadState>{};
    final raw = resp['channels'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] =
              ChannelReadState.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return result;
  }

  Future<ChannelReadState> getChannelReadState({required String channelId}) async {
    final resp = await _http.call(
      'chat/get_channel_read_state',
      {'channelId': channelId},
    );
    return ChannelReadState.fromJson(resp);
  }

  // ── Reactions ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    return _http.call('chat/add_reaction', {
      'channelId': channelId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  Future<Map<String, dynamic>> removeReaction({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    return _http.call('chat/remove_reaction', {
      'channelId': channelId,
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  // ── Pins ──────────────────────────────────────────────────────────────────

  Future<void> pinMessage({required String channelId, required String messageId}) async {
    await _http.call('chat/pin_message', {'channelId': channelId, 'messageId': messageId});
  }

  Future<void> unpinMessage({required String channelId, required String messageId}) async {
    await _http.call('chat/unpin_message', {'channelId': channelId, 'messageId': messageId});
  }

  // ── Channel settings ──────────────────────────────────────────────────────

  Future<void> muteChannel({required String channelId, int? muteUntil}) async {
    await _http.call('chat/mute_channel', {
      'channelId': channelId,
      if (muteUntil != null) 'muteUntil': muteUntil,
    });
  }

  Future<void> unmuteChannel(String channelId) async {
    await _http.call('chat/unmute_channel', {'channelId': channelId});
  }

  Future<void> archiveChannel(String channelId) async {
    await _http.call('chat/archive_channel', {'channelId': channelId});
  }

  Future<void> unarchiveChannel(String channelId) async {
    await _http.call('chat/unarchive_channel', {'channelId': channelId});
  }

  Future<void> clearHistory(String channelId) async {
    await _http.call('chat/clear_chat', {'channelId': channelId});
  }

  // ── Moderation ────────────────────────────────────────────────────────────

  Future<void> acceptDmRequest(String channelId) async {
    await _http.call('chat/accept_dm_request', {'channelId': channelId});
  }

  Future<void> deleteDmRequest(String channelId) async {
    await _http.call('chat/delete_dm_request', {'channelId': channelId});
  }

  Future<void> blockUser(String targetUserId) async {
    await _http.call('chat/block_user', {'targetUserId': targetUserId});
  }

  Future<void> unblockUser(String targetUserId) async {
    await _http.call('chat/unblock_user', {'targetUserId': targetUserId});
  }

  Future<void> reportUser({required String targetUserId, required String reason}) async {
    await _http.call('chat/report_user', {'targetUserId': targetUserId, 'reason': reason});
  }

  Future<void> reportMessage({
    required String channelId,
    required String messageId,
    required String reason,
  }) async {
    await _http.call('chat/report_message', {
      'channelId': channelId,
      'messageId': messageId,
      'reason': reason,
    });
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  Future<void> sendTypingIndicator(String channelId) async {
    await _http.call('chat/send_typing_indicator', {'channelId': channelId});
  }
}

/// Authoritative read-state for a single (channel, user). Returned by
/// [ChatApi.markRead] and [ChatApi.getChannelReadState]. The client uses
/// this to reconcile its local pointer + unread count in one round trip.
///
/// - [lastReadMessageId] is the monotonic pointer; everything with a
///   message id lexicographically > this is unread for this user (UUIDv7
///   ids sort chronologically).
/// - [unreadCount] is the authoritative total unread count for the
///   channel, computed on the server from the pointer.
/// - [firstUnreadMessageId] is empty when [unreadCount] is 0; otherwise
///   it is the oldest unread received message id, used as the anchor
///   for the unread divider and the initial chat-open jump.
/// - [firstUnreadCreateTime] is the anchor's create_time in unix seconds,
///   or 0 when there is no anchor.
class ChannelReadState {
  final String channelId;
  final String lastReadMessageId;
  final int lastReadMessageTime;
  final int unreadCount;
  final String firstUnreadMessageId;
  final int firstUnreadCreateTime;

  const ChannelReadState({
    this.channelId = '',
    required this.lastReadMessageId,
    this.lastReadMessageTime = 0,
    required this.unreadCount,
    required this.firstUnreadMessageId,
    required this.firstUnreadCreateTime,
  });

  factory ChannelReadState.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String asString(Object? v) => v is String ? v : '';

    return ChannelReadState(
      channelId: asString(json['channelId']),
      lastReadMessageId: asString(json['lastReadMessageId']),
      lastReadMessageTime: asInt(json['lastReadMessageTime']),
      unreadCount: asInt(json['unreadCount']),
      firstUnreadMessageId: asString(json['firstUnreadMessageId']),
      firstUnreadCreateTime: asInt(json['firstUnreadCreateTime']),
    );
  }

  bool get hasUnread => unreadCount > 0 && firstUnreadMessageId.isNotEmpty;
}

/// Result of [ChatApi.getMessages] — a paginated page of messages (newest
/// first) plus, on the first page, the authoritative read state bundled
/// in the same response to save a round-trip on chat open.
class GetMessagesResult {
  final List<Map<String, dynamic>> items;
  final String nextCursor;
  final bool hasMore;

  /// Present only on the first page (empty input cursor). Contains the
  /// server's read pointer, unread count, and first-unread anchor for
  /// this (user, channel).
  final ChannelReadState? readState;

  const GetMessagesResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.readState,
  });
}
