enum NotificationCategory { bids, messages, payments, documents, updates }

final class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
  });

  final String id;
  final String title;
  final String message;

  /// Backend type: `bid_received`, `payment_received`, `message_received`…
  final String type;
  final bool isRead;
  final DateTime createdAt;

  /// What [referenceId] points at: `bid`, `booking`, `payment`, `package`.
  final String? referenceType;
  final String? referenceId;

  NotificationCategory get category => switch (type) {
    'bid_received' ||
    'bid_accepted' ||
    'bid_rejected' ||
    'acceptance_expired' ||
    'acceptance_released' ||
    'package_booked' => NotificationCategory.bids,
    'message_received' => NotificationCategory.messages,
    'payment_received' => NotificationCategory.payments,
    'ticket_uploaded' ||
    'ticket_verified' ||
    'document_uploaded' => NotificationCategory.documents,
    _ => NotificationCategory.updates,
  };

  AppNotification markedRead() => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    isRead: true,
    createdAt: createdAt,
    referenceType: referenceType,
    referenceId: referenceId,
  );

  @override
  bool operator ==(Object other) =>
      other is AppNotification && other.id == id && other.isRead == isRead;

  @override
  int get hashCode => Object.hash(id, isRead);
}

/// One page of notifications.
final class NotificationPage {
  const NotificationPage(this.items, {required this.hasMore});

  final List<AppNotification> items;
  final bool hasMore;
}
