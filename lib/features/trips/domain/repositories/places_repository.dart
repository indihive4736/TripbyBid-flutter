import '../../../../core/error/result.dart';
import '../entities/new_trip_request.dart';
import '../entities/trip_request.dart';

/// Airports, train stations and cities the request form can pick from.
abstract interface class PlacesRepository {
  /// Places matching [query] for a [type] of trip, best match first:
  /// airports for flights, stations for trains, cities for hotels.
  ///
  /// An empty [query] returns a short list of popular places.
  Future<Result<List<Place>>> search(TripType type, String query);
}
