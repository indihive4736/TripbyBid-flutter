import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/trips/domain/entities/new_trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/repositories/places_repository.dart';
import 'package:tripbybid/features/trips/domain/usecases/search_places.dart';

class _RecordingPlaces implements PlacesRepository {
  final calls = <(TripType, String)>[];

  @override
  Future<Result<List<Place>>> search(TripType type, String query) async {
    calls.add((type, query));
    return const Ok([Place(name: 'Mumbai', code: 'BOM')]);
  }
}

void main() {
  test('searches the dataset for the trip type with a trimmed query', () async {
    final repository = _RecordingPlaces();
    final search = SearchPlacesUseCase(repository);

    final result = await search(const PlaceQuery(TripType.train, '  ndls '));

    expect(repository.calls, [(TripType.train, 'ndls')]);
    expect(result, isA<Ok<List<Place>>>());
  });
}
