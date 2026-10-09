import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/parse.dart';
import '../../domain/entities/app_notification.dart';

/// Notifications on the NestJS API. Throws `AppException`s.
abstract interface class NotificationsRemoteDataSource {
  Future<NotificationPage> getPage(int page);
  Future<int> getUnreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  static const pageSize = 20;

  @override
  Future<NotificationPage> getPage(int page) async {
    final json = await _api.get(
      '/notifications',
      query: {'page': '$page', 'limit': '$pageSize'},
    );
    return parseResponse(() {
      final root = JsonReader.of(json);
      return NotificationPage([
        for (final n in root.objects('data'))
          AppNotification(
            id: n.string('id'),
            title: n.stringOrNull('title') ?? '',
            message: n.stringOrNull('message') ?? '',
            type: n.stringOrNull('type') ?? 'system',
            isRead: n.boolean('is_read'),
            createdAt: n.date('created_at'),
            referenceType: n.stringOrNull('reference_type'),
            referenceId: n.stringOrNull('reference_id'),
          ),
      ], hasMore: root.object('pagination')?.boolean('hasNextPage') ?? false);
    });
  }

  @override
  Future<int> getUnreadCount() async {
    final json = await _api.get('/notifications/unread-count');
    return parseResponse(() => JsonReader.of(json).integer('count'));
  }

  @override
  Future<void> markRead(String id) => _api.patch('/notifications/$id/read');

  @override
  Future<void> markAllRead() => _api.patch('/notifications/read-all');
}
