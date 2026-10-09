import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/parse.dart';
import '../../domain/entities/chat.dart';

/// Booking chat on the NestJS API. Throws `AppException`s.
abstract interface class ChatRemoteDataSource {
  Future<List<Conversation>> getConversations();
  Future<List<ChatMessage>> getMessages(String bookingId);
  Future<ChatMessage> send(String bookingId, String text);
  Future<void> markRead(String bookingId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  const ChatRemoteDataSourceImpl(this._api, {required this.currentUserId});

  final ApiClient _api;

  /// The signed-in traveler, to tell their own messages apart.
  final String? Function() currentUserId;

  @override
  Future<List<Conversation>> getConversations() async {
    final json = await _api.get(
      '/messages/conversations',
      query: {'limit': '50'},
    );
    return parseResponse(() {
      final me = currentUserId();
      final list = [
        for (final c in readList(json))
          () {
            final request = c.object('booking_request');
            final last = c.object('last_message');
            final from = request?.stringOrNull('from_location') ?? '';
            final to = request?.stringOrNull('to_location') ?? '';
            return Conversation(
              bookingId: c.string('id'),
              requestId: request?.stringOrNull('id') ?? '',
              title: from == to || to.isEmpty ? from : '$from → $to',
              tripType: request?.stringOrNull('booking_type') ?? 'flight',
              agentName:
                  c.object('agent')?.stringOrNull('name') ?? 'Your agent',
              unreadCount: c.integer('unread_count'),
              lastMessage: last?.stringOrNull('content'),
              lastMessageMine:
                  me != null && last?.stringOrNull('sender_id') == me,
              updatedAt:
                  last?.dateOrNull('created_at') ??
                  c.dateOrNull('updated_at') ??
                  c.date('created_at'),
            );
          }(),
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Future<List<ChatMessage>> getMessages(String bookingId) async {
    final json = await _api.get(
      '/messages/booking/$bookingId',
      query: {'limit': '100'},
    );
    return parseResponse(() => [for (final m in readList(json)) _message(m)]);
  }

  @override
  Future<ChatMessage> send(String bookingId, String text) async {
    final json = await _api.post(
      '/messages',
      body: {'bookingId': bookingId, 'content': text, 'messageType': 'text'},
    );
    return parseResponse(() => _message(JsonReader.of(json)));
  }

  @override
  Future<void> markRead(String bookingId) =>
      _api.patch('/messages/booking/$bookingId/read');

  static ChatMessage _message(JsonReader m) => ChatMessage(
    id: m.string('id'),
    bookingId: m.string('booking_id'),
    senderId: m.stringOrNull('sender_id') ?? '',
    content: m.stringOrNull('content') ?? '',
    createdAt: m.date('created_at'),
    isRead: m.boolean('is_read'),
    isSystem: m.stringOrNull('message_type') == 'system',
  );
}
