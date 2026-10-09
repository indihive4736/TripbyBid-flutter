import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/notifications/domain/entities/app_notification.dart';
import 'package:tripbybid/features/notifications/domain/repositories/notifications_repository.dart';

/// In-memory [NotificationsRepository]. Script pages in [pages] (missing
/// pages fail); calls are recorded in [calls] as `method:arg`.
class FakeNotificationsRepository implements NotificationsRepository {
  final pages = <int, Result<NotificationPage>>{};
  Result<int> unreadResult = const Ok(0);
  Result<void> markReadResult = const Ok(null);
  Result<void> markAllResult = const Ok(null);

  final calls = <String>[];

  @override
  Future<Result<NotificationPage>> getPage(int page) async {
    calls.add('getPage:$page');
    return pages[page] ?? const Err(ServerFailure('not scripted'));
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    calls.add('getUnreadCount');
    return unreadResult;
  }

  @override
  Future<Result<void>> markRead(String id) async {
    calls.add('markRead:$id');
    return markReadResult;
  }

  @override
  Future<Result<void>> markAllRead() async {
    calls.add('markAllRead');
    return markAllResult;
  }
}

abstract final class NotificationFixtures {
  static AppNotification notification({
    String id = 'n-1',
    String title = 'New bid received',
    String message = 'AirTrek India bid ₹17,999 on Mumbai → Dubai',
    String type = 'bid_received',
    bool isRead = false,
    DateTime? createdAt,
    String? referenceType = 'bid',
    String? referenceId = 'bid-1',
  }) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 10, 10, 9),
    referenceType: referenceType,
    referenceId: referenceId,
  );
}
