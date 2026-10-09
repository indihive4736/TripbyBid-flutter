import '../../../../core/error/result.dart';
import '../entities/chat.dart';

abstract interface class ChatRepository {
  /// Threads for the traveler's bookings, most recent first.
  Future<Result<List<Conversation>>> getConversations();

  /// Messages of one booking, oldest first.
  Future<Result<List<ChatMessage>>> getMessages(String bookingId);

  Future<Result<ChatMessage>> send(String bookingId, String text);

  /// Mark the agent's messages in this thread as read.
  Future<Result<void>> markRead(String bookingId);
}
