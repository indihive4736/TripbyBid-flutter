import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

/// [params] is the 1-based page number.
class GetNotificationsUseCase implements UseCase<NotificationPage, int> {
  const GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<NotificationPage>> call(int params) =>
      _repository.getPage(params);
}

class GetUnreadCountUseCase implements UseCase<int, NoParams> {
  const GetUnreadCountUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<int>> call(NoParams params) => _repository.getUnreadCount();
}

/// [params] is the notification id.
class MarkNotificationReadUseCase implements UseCase<void, String> {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.markRead(params);
}

class MarkAllNotificationsReadUseCase implements UseCase<void, NoParams> {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.markAllRead();
}
