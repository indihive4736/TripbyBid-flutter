import 'dart:async';

import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/chat/domain/entities/chat.dart';
import 'package:tripbybid/features/chat/domain/repositories/chat_repository.dart';

/// In-memory [ChatRepository]. Script answers through the `*Result` fields
/// (or [sendHandler] to hold a send open); calls are recorded in [calls].
class FakeChatRepository implements ChatRepository {
  Result<List<Conversation>> conversationsResult = const Ok([]);
  Result<List<ChatMessage>> messagesResult = const Ok([]);
  Result<ChatMessage> sendResult = const Err(ServerFailure('not scripted'));
  Result<void> markReadResult = const Ok(null);

  /// When set, `send` waits for this instead of returning [sendResult].
  Future<Result<ChatMessage>> Function(String bookingId, String text)?
  sendHandler;

  final calls = <String>[];

  @override
  Future<Result<List<Conversation>>> getConversations() async {
    calls.add('getConversations');
    return conversationsResult;
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(String bookingId) async {
    calls.add('getMessages:$bookingId');
    return messagesResult;
  }

  @override
  Future<Result<ChatMessage>> send(String bookingId, String text) async {
    calls.add('send:$bookingId:$text');
    return sendHandler?.call(bookingId, text) ?? sendResult;
  }

  @override
  Future<Result<void>> markRead(String bookingId) async {
    calls.add('markRead:$bookingId');
    return markReadResult;
  }
}

/// A periodic timer the test fires by hand.
class ManualTimer implements Timer {
  ManualTimer(this.interval, this._onTick);

  final Duration interval;
  final void Function(Timer) _onTick;
  bool _active = true;
  int _ticks = 0;

  /// Every timer the factory created, newest last.
  static final created = <ManualTimer>[];

  static Timer factory(Duration interval, void Function(Timer) onTick) {
    final timer = ManualTimer(interval, onTick);
    created.add(timer);
    return timer;
  }

  void fire() {
    if (!_active) return;
    _ticks++;
    _onTick(this);
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _ticks;
}

abstract final class ChatFixtures {
  static const me = 'user-1';
  static const agent = 'agent-1';
  static const bookingId = '9a21c0d3-0000-4000-8000-000000000001';

  static Conversation conversation({
    String bookingId = ChatFixtures.bookingId,
    String agentName = 'AirTrek India',
    int unreadCount = 0,
    String? lastMessage = 'Your ticket is ready',
    bool lastMessageMine = false,
    String tripType = 'flight',
  }) => Conversation(
    bookingId: bookingId,
    requestId: 'req-1',
    title: 'Mumbai → Dubai',
    tripType: tripType,
    agentName: agentName,
    unreadCount: unreadCount,
    updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    lastMessage: lastMessage,
    lastMessageMine: lastMessageMine,
  );

  static ChatMessage message({
    required String id,
    String senderId = agent,
    String content = 'Hello',
    DateTime? createdAt,
    bool isRead = true,
    bool isSystem = false,
  }) => ChatMessage(
    id: id,
    bookingId: bookingId,
    senderId: senderId,
    content: content,
    createdAt: createdAt ?? DateTime(2026, 10, 10, 9),
    isRead: isRead,
    isSystem: isSystem,
  );
}
