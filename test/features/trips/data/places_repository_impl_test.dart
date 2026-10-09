import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/exceptions.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/trips/data/datasources/places_local_data_source.dart';
import 'package:tripbybid/features/trips/data/repositories/places_repository_impl.dart';
import 'package:tripbybid/features/trips/domain/entities/new_trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';

class _FailingSource implements PlacesLocalDataSource {
  @override
  Future<List<Place>> search(TripType type, String query) async =>
      throw const CacheException('Could not load the list of places.');
}

void main() {
  test('returns the ranked places', () async {
    final repository = PlacesRepositoryImpl(
      PlacesLocalDataSourceImpl.fromRaw(
        stations: [
          {'name': 'PUNE JN', 'code': 'PUNE'},
        ],
      ),
    );
    final result = await repository.search(TripType.train, 'pune');
    expect(
      result,
      isA<Ok<List<Place>>>().having(
        (r) => r.value.single.name,
        'name',
        'Pune Jn',
      ),
    );
  });

  test('a dataset that cannot load becomes a CacheFailure', () async {
    final result = await PlacesRepositoryImpl(
      _FailingSource(),
    ).search(TripType.flight, 'bom');
    expect(
      result,
      const Err<List<Place>>(
        CacheFailure('Could not load the list of places.'),
      ),
    );
  });
}
