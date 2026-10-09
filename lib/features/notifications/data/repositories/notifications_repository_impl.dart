import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<Result<NotificationPage>> getPage(int page) =>
      guard(() => _remote.getPage(page));

  @override
  Future<Result<int>> getUnreadCount() => guard(_remote.getUnreadCount);

  @override
  Future<Result<void>> markRead(String id) => guard(() => _remote.markRead(id));

  @override
  Future<Result<void>> markAllRead() => guard(_remote.markAllRead);
}
