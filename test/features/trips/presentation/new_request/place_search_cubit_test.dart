import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/usecases/search_places.dart';
import 'package:tripbybid/features/trips/presentation/new_request/place_search_cubit.dart';

import 'new_request_fakes.dart';

void main() {
  late FakePlacesRepository places;

  setUp(() => places = FakePlacesRepository());

  PlaceSearchCubit build() => PlaceSearchCubit(
    searchPlaces: SearchPlacesUseCase(places),
    debounce: const Duration(milliseconds: 20),
  );

  blocTest<PlaceSearchCubit, PlaceSearchState>(
    'opening lists popular places for the type',
    build: build,
    act: (cubit) => cubit.open(TripType.train),
    expect: () => [
      const PlaceSearchState(type: TripType.train),
      const PlaceSearchState(
        type: TripType.train,
        status: PlaceSearchStatus.ready,
        results: [FakePlacesRepository.newDelhi],
      ),
    ],
  );

  blocTest<PlaceSearchCubit, PlaceSearchState>(
    'debounces typing into one search',
    build: build,
    act: (cubit) async {
      await cubit.open(TripType.flight);
      cubit
        ..search('d')
        ..search('du')
        ..search('dub');
      await Future<void>.delayed(const Duration(milliseconds: 60));
    },
    verify: (cubit) {
      expect(places.queries, ['', 'dub']);
      expect(cubit.state.query, 'dub');
      expect(cubit.state.results, [FakePlacesRepository.dubai]);
      expect(cubit.state.status, PlaceSearchStatus.ready);
    },
  );

  blocTest<PlaceSearchCubit, PlaceSearchState>(
    'shows a failure and can retry',
    build: build,
    act: (cubit) async {
      places.failure = const Err(CacheFailure('Could not load places.'));
      await cubit.open(TripType.hotel);
      expect(cubit.state.status, PlaceSearchStatus.failure);
      expect(cubit.state.message, 'Could not load places.');
      places.failure = null;
      await cubit.retry();
    },
    verify: (cubit) {
      expect(cubit.state.status, PlaceSearchStatus.ready);
      expect(cubit.state.results, [FakePlacesRepository.goa]);
    },
  );
}
