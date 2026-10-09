import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/new_trip_request.dart';
import '../entities/trip_request.dart';
import '../repositories/places_repository.dart';

/// What to look up: the kind of trip decides the dataset.
final class PlaceQuery {
  const PlaceQuery(this.type, this.text);

  final TripType type;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is PlaceQuery && other.type == type && other.text == text;

  @override
  int get hashCode => Object.hash(type, text);

  @override
  String toString() => 'PlaceQuery(${type.name}, "$text")';
}

/// Finds airports, stations or cities for the request form.
class SearchPlacesUseCase implements UseCase<List<Place>, PlaceQuery> {
  SearchPlacesUseCase(this._repository);

  final PlacesRepository _repository;

  @override
  Future<Result<List<Place>>> call(PlaceQuery params) =>
      _repository.search(params.type, params.text.trim());
}
