import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<Result<List<Conversation>>> getConversations() =>
      guard(_remote.getConversations);

  @override
  Future<Result<List<ChatMessage>>> getMessages(String bookingId) =>
      guard(() => _remote.getMessages(bookingId));

  @override
  Future<Result<ChatMessage>> send(String bookingId, String text) =>
      guard(() => _remote.send(bookingId, text));

  @override
  Future<Result<void>> markRead(String bookingId) =>
      guard(() => _remote.markRead(bookingId));
}
