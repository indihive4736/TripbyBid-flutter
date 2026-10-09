part of 'notifications_cubit.dart';

enum NotificationFilter { all, unread }

/// Where tapping a notification leads.
sealed class NotificationTarget extends Equatable {
  const NotificationTarget();

  @override
  List<Object?> get props => [];
}

/// The booking detail of a request.
final class TripTarget extends NotificationTarget {
  const TripTarget(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

/// The chat of a booking.
final class ChatTarget extends NotificationTarget {
  const ChatTarget(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// The trips tab, when the request cannot be resolved.
final class TripsTabTarget extends NotificationTarget {
  const TripsTabTarget();
}

final class PaymentsTarget extends NotificationTarget {
  const PaymentsTarget();
}

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    this.filter = NotificationFilter.all,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  /// Every loaded notification, newest first.
  final List<AppNotification> items;

  /// The last page fetched (1-based).
  final int page;
  final bool hasMore;
  final NotificationFilter filter;
  final bool loadingMore;
  final bool loadMoreFailed;

  /// What the list shows under [filter].
  List<AppNotification> get visible => switch (filter) {
    NotificationFilter.all => items,
    NotificationFilter.unread => items.where((n) => !n.isRead).toList(),
  };

  /// Unread among the loaded notifications.
  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsLoaded copyWith({
    List<AppNotification>? items,
    int? page,
    bool? hasMore,
    NotificationFilter? filter,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => NotificationsLoaded(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    filter: filter ?? this.filter,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );

  @override
  List<Object?> get props => [
    items,
    page,
    hasMore,
    filter,
    loadingMore,
    loadMoreFailed,
  ];
}
