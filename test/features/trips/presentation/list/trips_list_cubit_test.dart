import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';
import 'package:tripbybid/features/trips/presentation/list/trips_list_cubit.dart';

import '../../trips_fakes.dart';

void main() {
  late FakeTripsRepository repository;

  final bidding = TripFixtures.request(id: 'a1', bidsCount: 2);
  final hotel = TripFixtures.request(
    id: 'a2',
    type: TripType.hotel,
    status: 'pending',
  );
  final completed = TripFixtures.request(
    id: 'p1',
    status: 'completed',
    booking: TripFixtures.booking(status: 'completed'),
  );
  final expired = TripFixtures.request(
    id: 'p2',
    type: TripType.train,
    status: 'expired',
  );
  final all = [bidding, hotel, completed, expired];

  setUp(() => repository = FakeTripsRepository());

  TripsListCubit build() =>
      TripsListCubit(getMyTrips: GetMyTripsUseCase(repository));

  blocTest<TripsListCubit, TripsListState>(
    'loads the trips on the Active segment',
    setUp: () => repository.myTripsResult = Ok(all),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [TripsListLoaded(trips: all, segment: TripSegment.active)],
  );

  blocTest<TripsListCubit, TripsListState>(
    'emits a failure when loading fails',
    setUp: () => repository.myTripsResult = const Err(NetworkFailure('Off')),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [const TripsListFailure('Off')],
  );

  blocTest<TripsListCubit, TripsListState>(
    'keeps the list when a refresh fails',
    setUp: () => repository.myTripsResult = const Err(NetworkFailure('Off')),
    build: build,
    seed: () => TripsListLoaded(trips: all, segment: TripSegment.past),
    act: (cubit) => cubit.load(),
    expect: () => <TripsListState>[],
  );

  blocTest<TripsListCubit, TripsListState>(
    'switches segment and type filter',
    setUp: () => repository.myTripsResult = Ok(all),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit
        ..selectSegment(TripSegment.past)
        ..filterType(TripType.train);
    },
    skip: 1,
    expect: () => [
      TripsListLoaded(trips: all, segment: TripSegment.past),
      TripsListLoaded(
        trips: all,
        segment: TripSegment.past,
        type: TripType.train,
      ),
    ],
  );

  group('TripsListLoaded', () {
    test('splits active and past trips with counts', () {
      final state = TripsListLoaded(trips: all, segment: TripSegment.active);
      expect(state.visible, [bidding, hotel]);
      expect(state.count(TripSegment.active), 2);
      expect(state.count(TripSegment.past), 2);
      expect(state.count(TripSegment.all), 4);
    });

    test('applies the type filter to the list and the counts', () {
      final state = TripsListLoaded(
        trips: all,
        segment: TripSegment.all,
        type: TripType.flight,
      );
      expect(state.visible, [bidding, completed]);
      expect(state.count(TripSegment.past), 1);
    });
  });
}
