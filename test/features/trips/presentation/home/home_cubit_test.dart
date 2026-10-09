import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_summaries.dart';
import 'package:tripbybid/features/trips/domain/usecases/get_active_bids_usecase.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';
import 'package:tripbybid/features/trips/presentation/home/home_cubit.dart';

import '../../../notifications/notifications_fakes.dart';
import '../../trips_fakes.dart';

void main() {
  late FakeTripsRepository trips;
  late FakeNotificationsRepository notifications;

  final today = DateTime(2026, 10, 10);
  final bidsIn = TripFixtures.request(id: 'bids-1', bidsCount: 3);
  final booked = TripFixtures.request(
    id: 'booked-1',
    status: 'confirmed',
    departDate: DateTime(2026, 10, 13),
    booking: TripFixtures.booking(price: 6998),
  );

  setUp(() {
    trips = FakeTripsRepository();
    notifications = FakeNotificationsRepository();
  });

  HomeCubit build() => HomeCubit(
    getMyTrips: GetMyTripsUseCase(trips),
    getActiveBids: GetActiveBidsUseCase(trips),
    getUnreadCount: GetUnreadCountUseCase(notifications),
    now: () => today,
  );

  blocTest<HomeCubit, HomeState>(
    'loads the highlight, live bids with best offer, stats and unread count',
    setUp: () {
      trips
        ..myTripsResult = Ok([bidsIn, booked])
        ..activeBidsResult = Ok([
          TripFixtures.bid(price: 18450),
          TripFixtures.bid(id: 'b2', price: 18000),
        ]);
      notifications.unreadResult = const Ok(4);
    },
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      HomeLoaded(
        highlight: TripHighlight(HighlightKind.upcoming, booked),
        liveBids: [
          LiveBidSummary(trip: bidsIn, bestOffer: 18000, savingsPercent: 10),
        ],
        unreadCount: 4,
        bookedCount: 1,
        totalSpent: 6998,
      ),
    ],
    verify: (_) => expect(trips.calls, contains('getActiveBids:bids-1')),
  );

  blocTest<HomeCubit, HomeState>(
    'shows live bids without a price when offers fail to load',
    setUp: () {
      trips
        ..myTripsResult = Ok([bidsIn])
        ..activeBidsResult = const Err(NetworkFailure());
      notifications.unreadResult = const Err(NetworkFailure());
    },
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      HomeLoaded(
        highlight: TripHighlight(HighlightKind.bidsIn, bidsIn),
        liveBids: [LiveBidSummary(trip: bidsIn)],
        unreadCount: 0,
        bookedCount: 0,
        totalSpent: 0,
      ),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'looks up offers for at most five requests',
    setUp: () => trips.myTripsResult = Ok([
      for (var i = 0; i < 7; i++)
        TripFixtures.request(id: 'r$i-0000000', bidsCount: 1),
    ]),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(
        trips.calls.where((c) => c.startsWith('getActiveBids')),
        hasLength(HomeCubit.maxLiveBids),
      );
      expect((cubit.state as HomeLoaded).liveBids, hasLength(5));
    },
  );

  blocTest<HomeCubit, HomeState>(
    'emits a failure when the trips fail to load',
    setUp: () => trips.myTripsResult = const Err(ServerFailure('Down')),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const HomeFailure('Down')],
  );

  blocTest<HomeCubit, HomeState>(
    'retries from a failure through loading',
    setUp: () => trips.myTripsResult = const Ok([]),
    build: build,
    seed: () => const HomeFailure('Down'),
    act: (cubit) => cubit.load(),
    expect: () => [
      const HomeLoading(),
      const HomeLoaded(
        highlight: null,
        liveBids: [],
        unreadCount: 0,
        bookedCount: 0,
        totalSpent: 0,
      ),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'keeps the content when a refresh fails',
    setUp: () => trips.myTripsResult = const Err(ServerFailure('Down')),
    build: build,
    seed: () => const HomeLoaded(
      highlight: null,
      liveBids: [],
      unreadCount: 2,
      bookedCount: 0,
      totalSpent: 0,
    ),
    act: (cubit) => cubit.load(),
    expect: () => <HomeState>[],
  );
}
