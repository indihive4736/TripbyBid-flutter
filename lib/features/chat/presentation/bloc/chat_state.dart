part of 'chat_cubit.dart';

enum ChatStatus { loading, ready, failure }

/// A message typed on this device that the server has not confirmed yet.
final class PendingMessage extends Equatable {
  const PendingMessage({
    required this.localId,
    required this.text,
    required this.createdAt,
    this.failed = false,
  });

  final String localId;
  final String text;
  final DateTime createdAt;

  /// Sending failed; the traveler can retry.
  final bool failed;

  PendingMessage copyWith({bool? failed}) => PendingMessage(
    localId: localId,
    text: text,
    createdAt: createdAt,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [localId, text, createdAt, failed];
}

final class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.currentUserId = '',
    this.conversation,
    this.messages = const [],
    this.pending = const [],
    this.errorMessage,
  });

  final ChatStatus status;
  final String currentUserId;

  /// Agent name and trip title; null until loaded (or when not found).
  final Conversation? conversation;

  /// Confirmed messages, oldest first, unique by id.
  final List<ChatMessage> messages;

  /// Messages being sent (or that failed), shown after [messages].
  final List<PendingMessage> pending;

  /// Set when [status] is [ChatStatus.failure].
  final String? errorMessage;

  bool get isEmpty => messages.isEmpty && pending.isEmpty;

  bool isMine(ChatMessage message) =>
      !message.isSystem && message.senderId == currentUserId;

  ChatState copyWith({
    ChatStatus? status,
    String? currentUserId,
    Conversation? conversation,
    List<ChatMessage>? messages,
    List<PendingMessage>? pending,
    String? errorMessage,
  }) => ChatState(
    status: status ?? this.status,
    currentUserId: currentUserId ?? this.currentUserId,
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    pending: pending ?? this.pending,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    currentUserId,
    conversation,
    messages,
    pending,
    errorMessage,
  ];
}
