import 'trip_request.dart';

/// An airport, station or city picked in the request form.
final class Place {
  const Place({required this.name, this.code, this.city, this.country});

  /// Airport/station name, or the city for hotels.
  final String name;

  /// IATA or station code.
  final String? code;
  final String? city;

  /// ISO country code (hotels).
  final String? country;

  /// How the backend's `fromLocation`/`toLocation` strings read:
  /// "Mumbai (BOM)" or just the city.
  String get label => code == null ? name : '$name ($code)';

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.name == name &&
      other.code == code &&
      other.city == city &&
      other.country == country;

  @override
  int get hashCode => Object.hash(name, code, city, country);

  @override
  String toString() => 'Place($label)';
}

/// What the traveler fills in to post a request.
final class NewTripRequest {
  const NewTripRequest({
    required this.type,
    required this.from,
    required this.to,
    required this.departDate,
    required this.budget,
    required this.contactEmail,
    required this.contactPhone,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.seniors = 0,
    this.rooms = 1,
    this.tripType = 'one-way',
    this.travelClass,
    this.directOnly = false,
    this.flexibleDates = false,
    this.preferredAirline,
    this.quota,
    this.berthPreference,
    this.roomType,
    this.starRating,
    this.breakfastIncluded = false,
    this.requirements,
  });

  final TripType type;

  /// For hotels [from] is the city and [to] the area (or the city again).
  final Place from;
  final Place to;
  final DateTime departDate;

  /// Round-trip return or hotel check-out.
  final DateTime? returnDate;
  final double budget;
  final String contactEmail;
  final String contactPhone;

  final int adults;
  final int children;

  /// Flights only.
  final int infants;

  /// Trains only.
  final int seniors;

  /// Hotels only.
  final int rooms;

  /// Flights: `one-way`, `round-trip`.
  final String tripType;

  /// Flight cabin or train class API value; defaults per type when null.
  final String? travelClass;
  final bool directOnly;
  final bool flexibleDates;
  final String? preferredAirline;
  final String? quota;
  final String? berthPreference;
  final String? roomType;
  final int? starRating;
  final bool breakfastIncluded;
  final String? requirements;
}
