import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../trips/domain/usecases/trip_queries.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';

part 'notifications_state.dart';

/// The notification list: paging, the All / Unread filter, marking read and
/// where a tap leads.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
    required GetMyTripsUseCase getMyTrips,
  }) : _getNotifications = getNotifications,
       _markRead = markRead,
       _markAllRead = markAllRead,
       _getMyTrips = getMyTrips,
       super(const NotificationsLoading());

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final GetMyTripsUseCase _getMyTrips;

  NotificationFilter _filter = NotificationFilter.all;

  /// Booking id → request id, from the traveler's trips. Notifications
  /// reference bookings, but trip screens are keyed by request.
  Map<String, String> _requestByBooking = const {};
  Future<void>? _inFlight;

  /// Loads the first page (and the trips used to resolve links). Once
  /// loaded, later calls refresh in place and keep the list on failure.
  Future<void> load() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    if (state is NotificationsFailure) emit(const NotificationsLoading());
    final tripsFuture = _getMyTrips(const NoParams());
    final pageResult = await _getNotifications(1);
    final tripsResult = await tripsFuture;
    if (isClosed) return;

    if (tripsResult case Ok(value: final trips)) {
      _requestByBooking = {
        for (final t in trips)
          if (t.booking case final booking?) booking.id: t.id,
      };
    }

    switch (pageResult) {
      case Ok(:final value):
        emit(
          NotificationsLoaded(
            items: value.items,
            page: 1,
            hasMore: value.hasMore,
            filter: _filter,
          ),
        );
      case Err(:final failure):
        if (state is! NotificationsLoaded) {
          emit(NotificationsFailure(failure.message));
        }
    }
  }

  /// Fetches the next page; no-op while one is loading or at the end.
  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationsLoaded ||
        !current.hasMore ||
        current.loadingMore ||
        _inFlight != null) {
      return;
    }
    emit(current.copyWith(loadingMore: true, loadMoreFailed: false));
    final result = await _getNotifications(current.page + 1);
    if (isClosed) return;
    final latest = state;
    if (latest is! NotificationsLoaded) return;
    emit(switch (result) {
      Ok(:final value) => latest.copyWith(
        items: [
          ...latest.items,
          // Skip items that shifted onto this page since the last fetch.
          ...value.items.where(
            (n) => !latest.items.any((existing) => existing.id == n.id),
          ),
        ],
        page: current.page + 1,
        hasMore: value.hasMore,
        loadingMore: false,
      ),
      Err() => latest.copyWith(loadingMore: false, loadMoreFailed: true),
    });
  }

  void setFilter(NotificationFilter filter) {
    _filter = filter;
    if (state case final NotificationsLoaded s) {
      emit(s.copyWith(filter: filter));
    }
  }

  /// Marks [notification] read (optimistically) and returns where a tap on
  /// it should lead, or null when it links nowhere.
  NotificationTarget? open(AppNotification notification) {
    if (!notification.isRead) unawaited(_markOneRead(notification));
    return targetFor(notification);
  }

  Future<void> _markOneRead(AppNotification notification) async {
    _replace(notification.id, (n) => n.markedRead());
    final result = await _markRead(notification.id);
    if (result is Err && !isClosed) {
      _replace(notification.id, (_) => notification);
    }
  }

  /// Marks everything read. Returns false (and restores the list) when the
  /// server refused.
  Future<bool> markAllRead() async {
    final current = state;
    if (current is! NotificationsLoaded) return false;
    emit(
      current.copyWith(items: [for (final n in current.items) n.markedRead()]),
    );
    final result = await _markAllRead(const NoParams());
    if (isClosed) return result is Ok;
    if (result is Err) {
      final latest = state;
      if (latest is NotificationsLoaded) {
        final before = {for (final n in current.items) n.id: n};
        emit(
          latest.copyWith(
            items: [for (final n in latest.items) before[n.id] ?? n],
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _replace(String id, AppNotification Function(AppNotification) update) {
    final current = state;
    if (current is! NotificationsLoaded) return;
    emit(
      current.copyWith(
        items: [for (final n in current.items) n.id == id ? update(n) : n],
      ),
    );
  }

  /// Where [notification] leads, from its reference.
  NotificationTarget? targetFor(AppNotification notification) {
    final ref = notification.referenceId;
    if (ref == null) return null;
    return switch (notification.referenceType) {
      'payment' => const PaymentsTarget(),
      'booking' when notification.category == NotificationCategory.messages =>
        ChatTarget(ref),
      'booking' => switch (_requestByBooking[ref]) {
        final requestId? => TripTarget(requestId),
        null => const TripsTabTarget(),
      },
      // Bid ids cannot be mapped to a request from the trips list.
      'bid' => const TripsTabTarget(),
      _ => null,
    };
  }
}
