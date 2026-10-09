import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase implements UseCase<List<Conversation>, NoParams> {
  const GetConversationsUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<List<Conversation>>> call(NoParams params) =>
      _repository.getConversations();
}

/// [params] is the booking id.
class GetMessagesUseCase implements UseCase<List<ChatMessage>, String> {
  const GetMessagesUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<List<ChatMessage>>> call(String params) =>
      _repository.getMessages(params);
}

final class SendMessageParams {
  const SendMessageParams(this.bookingId, this.text);

  final String bookingId;
  final String text;
}

class SendMessageUseCase implements UseCase<ChatMessage, SendMessageParams> {
  const SendMessageUseCase(this._repository);

  final ChatRepository _repository;

  static const maxLength = 5000;

  @override
  Future<Result<ChatMessage>> call(SendMessageParams params) async {
    final text = params.text.trim();
    if (text.isEmpty) {
      return const Err(ValidationFailure('Type a message first.'));
    }
    if (text.length > maxLength) {
      return const Err(
        ValidationFailure('Messages can be up to 5,000 characters.'),
      );
    }
    return _repository.send(params.bookingId, text);
  }
}

/// [params] is the booking id.
class MarkConversationReadUseCase implements UseCase<void, String> {
  const MarkConversationReadUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.markRead(params);
}
