/// Type-specific trip details. Fields that do not apply to the trip type are
/// null; counts default to 0.
final class TripDetails {
  const TripDetails({
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.seniors = 0,
    this.rooms,
    this.tripType,
    this.travelClass,
    this.fromCode,
    this.toCode,
    this.fromName,
    this.toName,
    this.fromCity,
    this.toCity,
    this.preferredAirline,
    this.directOnly = false,
    this.flexibleDates = false,
    this.quota,
    this.berthPreference,
    this.preferredDepartureTime,
    this.destinationCity,
    this.destinationArea,
    this.destinationCountry,
    this.roomType,
    this.starRating,
    this.breakfastIncluded = false,
  });

  final int adults;
  final int children;
  final int infants;
  final int seniors;

  /// Hotels.
  final int? rooms;

  /// Flights: `one-way`, `round-trip`, `multi-city`.
  final String? tripType;

  /// Flight cabin or train class, as the API value (`economy`, `ac-2-tier`…).
  final String? travelClass;

  /// Airport (flight) or station (train) codes and names.
  final String? fromCode;
  final String? toCode;
  final String? fromName;
  final String? toName;
  final String? fromCity;
  final String? toCity;

  final String? preferredAirline;
  final bool directOnly;
  final bool flexibleDates;

  /// Trains.
  final String? quota;
  final String? berthPreference;
  final String? preferredDepartureTime;

  /// Hotels.
  final String? destinationCity;
  final String? destinationArea;
  final String? destinationCountry;
  final String? roomType;
  final int? starRating;
  final bool breakfastIncluded;

  int get travellers => adults + children + infants + seniors;
}
