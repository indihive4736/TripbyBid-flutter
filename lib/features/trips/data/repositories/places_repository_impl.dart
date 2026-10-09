import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/places_local_data_source.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._local);

  final PlacesLocalDataSource _local;

  @override
  Future<Result<List<Place>>> search(TripType type, String query) =>
      guard(() => _local.search(type, query));
}
