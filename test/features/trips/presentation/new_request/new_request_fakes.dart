import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/trips/domain/entities/new_trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/repositories/places_repository.dart';

/// In-memory [PlacesRepository]: returns the places whose name or code
/// contains the query; set [failure] to script an error.
class FakePlacesRepository implements PlacesRepository {
  FakePlacesRepository([this.places = defaultPlaces]);

  final Map<TripType, List<Place>> places;
  Result<List<Place>>? failure;
  final queries = <String>[];

  static const mumbai = Place(
    name: 'Chhatrapati Shivaji Maharaj International Airport',
    code: 'BOM',
    city: 'Mumbai',
    country: 'IN',
  );
  static const dubai = Place(
    name: 'Dubai International Airport',
    code: 'DXB',
    city: 'Dubai',
    country: 'AE',
  );
  static const newDelhi = Place(name: 'New Delhi', code: 'NDLS', country: 'IN');
  static const goa = Place(name: 'Goa', city: 'Goa', country: 'IN');

  static const defaultPlaces = {
    TripType.flight: [mumbai, dubai],
    TripType.train: [newDelhi],
    TripType.hotel: [goa],
  };

  @override
  Future<Result<List<Place>>> search(TripType type, String query) async {
    queries.add(query);
    if (failure case final f?) return f;
    final q = query.toLowerCase();
    return Ok([
      for (final p in places[type] ?? const <Place>[])
        if (p.name.toLowerCase().contains(q) ||
            (p.code?.toLowerCase().contains(q) ?? false) ||
            (p.city?.toLowerCase().contains(q) ?? false))
          p,
    ]);
  }
}
