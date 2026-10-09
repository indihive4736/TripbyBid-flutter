import '../../../../core/error/result.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  /// Newest first; [page] starts at 1.
  Future<Result<NotificationPage>> getPage(int page);
  Future<Result<int>> getUnreadCount();
  Future<Result<void>> markRead(String id);
  Future<Result<void>> markAllRead();
}
