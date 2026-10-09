import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/notifications/domain/entities/app_notification.dart';
import 'package:tripbybid/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:tripbybid/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';

import '../../trips/trips_fakes.dart';
import '../notifications_fakes.dart';

void main() {
  late FakeNotificationsRepository notifications;
  late FakeTripsRepository trips;

  final unread = NotificationFixtures.notification();
  final read = NotificationFixtures.notification(id: 'n-2', isRead: true);
  final older = NotificationFixtures.notification(id: 'n-3');

  setUp(() {
    notifications = FakeNotificationsRepository();
    trips = FakeTripsRepository();
  });

  NotificationsCubit build() => NotificationsCubit(
    getNotifications: GetNotificationsUseCase(notifications),
    markRead: MarkNotificationReadUseCase(notifications),
    markAllRead: MarkAllNotificationsReadUseCase(notifications),
    getMyTrips: GetMyTripsUseCase(trips),
  );

  group('load', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'emits the first page',
      setUp: () => notifications.pages[1] = Ok(
        NotificationPage([unread, read], hasMore: true),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        NotificationsLoaded(items: [unread, read], page: 1, hasMore: true),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'emits a failure when the first page fails',
      setUp: () =>
          notifications.pages[1] = const Err(NetworkFailure('Offline')),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [const NotificationsFailure('Offline')],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'keeps the list when a refresh fails',
      build: build,
      seed: () => NotificationsLoaded(items: [unread], page: 1, hasMore: false),
      act: (cubit) => cubit.load(),
      expect: () => <NotificationsState>[],
    );
  });

  group('loadMore', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'appends the next page',
      setUp: () => notifications.pages[2] = Ok(
        NotificationPage([older], hasMore: false),
      ),
      build: build,
      seed: () => NotificationsLoaded(items: [unread], page: 1, hasMore: true),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        NotificationsLoaded(
          items: [unread],
          page: 1,
          hasMore: true,
          loadingMore: true,
        ),
        NotificationsLoaded(items: [unread, older], page: 2, hasMore: false),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'flags a failed page and keeps the list',
      build: build,
      seed: () => NotificationsLoaded(items: [unread], page: 1, hasMore: true),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        NotificationsLoaded(
          items: [unread],
          page: 1,
          hasMore: true,
          loadingMore: true,
        ),
        NotificationsLoaded(
          items: [unread],
          page: 1,
          hasMore: true,
          loadMoreFailed: true,
        ),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'does nothing at the end of the list',
      build: build,
      seed: () => NotificationsLoaded(items: [unread], page: 1, hasMore: false),
      act: (cubit) => cubit.loadMore(),
      expect: () => <NotificationsState>[],
      verify: (_) => expect(notifications.calls, isEmpty),
    );
  });

  test('the unread filter shows only unread notifications', () {
    final state = NotificationsLoaded(
      items: [unread, read],
      page: 1,
      hasMore: false,
      filter: NotificationFilter.unread,
    );
    expect(state.visible, [unread]);
    expect(state.unreadCount, 1);
  });

  group('open', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'marks the notification read optimistically',
      build: build,
      seed: () => NotificationsLoaded(items: [unread], page: 1, hasMore: false),
      act: (cubit) => cubit.open(unread),
      expect: () => [
        NotificationsLoaded(
          items: [unread.markedRead()],
          page: 1,
          hasMore: false,
        ),
      ],
      verify: (_) => expect(notifications.calls, ['markRead:n-1']),
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'restores the unread state when the server refuses',
      setUp: () =>
          notifications.markReadResult = const Err(ServerFailure('Nope')),
      build: build,
      seed: () => NotificationsLoaded(items: [unread], page: 1, hasMore: false),
      act: (cubit) async {
        cubit.open(unread);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        NotificationsLoaded(
          items: [unread.markedRead()],
          page: 1,
          hasMore: false,
        ),
        NotificationsLoaded(items: [unread], page: 1, hasMore: false),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'does not mark an already read notification again',
      build: build,
      seed: () => NotificationsLoaded(items: [read], page: 1, hasMore: false),
      act: (cubit) => cubit.open(read),
      expect: () => <NotificationsState>[],
      verify: (_) => expect(notifications.calls, isEmpty),
    );
  });

  group('targetFor', () {
    AppNotification ref(String? type, String? id, {String kind = 'x'}) =>
        NotificationFixtures.notification(
          type: kind,
          referenceType: type,
          referenceId: id,
        );

    test('resolves a booking to its request once trips are loaded', () async {
      trips.myTripsResult = Ok([
        TripFixtures.request(
          id: 'req-1',
          status: 'confirmed',
          booking: TripFixtures.booking(id: 'booking-9'),
        ),
      ]);
      notifications.pages[1] = const Ok(NotificationPage([], hasMore: false));
      final cubit = build();
      await cubit.load();

      expect(
        cubit.targetFor(ref('booking', 'booking-9', kind: 'ticket_uploaded')),
        const TripTarget('req-1'),
      );
      expect(
        cubit.targetFor(ref('booking', 'unknown', kind: 'ticket_uploaded')),
        const TripsTabTarget(),
      );
    });

    test('opens the chat for message notifications', () {
      expect(
        build().targetFor(ref('booking', 'b-1', kind: 'message_received')),
        const ChatTarget('b-1'),
      );
    });

    test('maps bids, payments and missing references', () {
      final cubit = build();
      expect(cubit.targetFor(ref('bid', 'bid-1')), const TripsTabTarget());
      expect(cubit.targetFor(ref('payment', 'p-1')), const PaymentsTarget());
      expect(cubit.targetFor(ref(null, null)), isNull);
      expect(cubit.targetFor(ref('package', 'pk-1')), isNull);
    });
  });

  group('markAllRead', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'marks every notification read',
      build: build,
      seed: () =>
          NotificationsLoaded(items: [unread, older], page: 1, hasMore: false),
      act: (cubit) async => expect(await cubit.markAllRead(), isTrue),
      expect: () => [
        NotificationsLoaded(
          items: [unread.markedRead(), older.markedRead()],
          page: 1,
          hasMore: false,
        ),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'restores the list and reports failure',
      setUp: () =>
          notifications.markAllResult = const Err(ServerFailure('Nope')),
      build: build,
      seed: () => NotificationsLoaded(items: [unread], page: 1, hasMore: false),
      act: (cubit) async => expect(await cubit.markAllRead(), isFalse),
      expect: () => [
        NotificationsLoaded(
          items: [unread.markedRead()],
          page: 1,
          hasMore: false,
        ),
        NotificationsLoaded(items: [unread], page: 1, hasMore: false),
      ],
    );
  });
}
