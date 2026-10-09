import 'bid.dart';
import 'booking.dart';
import 'trip_details.dart';
import 'trip_stage.dart';

enum TripType {
  flight,
  train,
  hotel,

  /// Holiday package bought from the catalogue (web only for now).
  package;

  static TripType parse(String value) => switch (value) {
    'train' => train,
    'hotel' => hotel,
    'package' => package,
    _ => flight,
  };

  String get apiValue => name;
}

/// A traveler's request for a trip, which agents bid on.
///
/// Large aggregate: compared by identity, not value.
final class TripRequest {
  const TripRequest({
    required this.id,
    required this.type,
    required this.fromLocation,
    required this.toLocation,
    required this.departDate,
    required this.budget,
    required this.status,
    required this.bidsCount,
    required this.createdAt,
    this.returnDate,
    this.requirements,
    this.expiresAt,
    this.details,
    this.booking,
    this.bids = const [],
  });

  final String id;
  final TripType type;

  /// For hotels both locations are the city.
  final String fromLocation;
  final String toLocation;

  /// Departure, journey or check-in date (date only).
  final DateTime departDate;

  /// Return or check-out date.
  final DateTime? returnDate;

  /// Total budget in INR as entered by the traveler.
  final double budget;
  final String? requirements;

  /// Raw backend status; use [stage] for UI decisions.
  final String status;

  /// Placed, non-withdrawn bids.
  final int bidsCount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final TripDetails? details;

  /// The booking, once paid (list and detail endpoints embed it).
  final Booking? booking;

  /// Every non-withdrawn bid (detail endpoint only; empty in lists).
  final List<Bid> bids;

  TripStage get stage => TripStage.of(status, bidsCount: bidsCount);

  /// The bid the traveler accepted and must pay for, if any.
  Bid? get acceptedBid =>
      bids.where((b) => b.status == BidStatus.accepted).firstOrNull;

  /// The bid that was paid for and booked, if any.
  Bid? get selectedBid =>
      bids.where((b) => b.status == BidStatus.selected).firstOrNull;

  /// Short human id: `#A9C3E05F`.
  String get shortId =>
      '#${id.replaceAll('-', '').substring(0, 8).toUpperCase()}';
}
