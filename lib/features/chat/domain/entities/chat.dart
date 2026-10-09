/// A chat thread with the agent of one booking. Chat opens once a trip is
/// booked (paid); there is no chat before that.
final class Conversation {
  const Conversation({
    required this.bookingId,
    required this.requestId,
    required this.title,
    required this.tripType,
    required this.agentName,
    required this.unreadCount,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageMine = false,
  });

  final String bookingId;
  final String requestId;

  /// "Mumbai → Dubai".
  final String title;

  /// `flight`, `train`, `hotel`, `package`.
  final String tripType;
  final String agentName;
  final int unreadCount;
  final String? lastMessage;
  final bool lastMessageMine;
  final DateTime updatedAt;
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.isSystem = false,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  /// Automatic messages (status changes), shown centred.
  final bool isSystem;

  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      other.id == id &&
      other.content == content &&
      other.isRead == isRead;

  @override
  int get hashCode => Object.hash(id, content, isRead);
}
