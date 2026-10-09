enum BidStatus {
  /// Live offer.
  active,

  /// Accepted by the traveler; fare held until [Bid.paymentDueAt].
  accepted,

  /// Paid for and booked.
  selected,

  rejected,
  withdrawn,
  expired;

  static BidStatus parse(String value) =>
      BidStatus.values.where((s) => s.name == value).firstOrNull ?? expired;
}

/// An agent's offer on a trip request.
final class Bid {
  const Bid({
    required this.id,
    required this.requestId,
    required this.agentId,
    required this.price,
    required this.status,
    required this.agentName,
    required this.createdAt,
    this.agentRating = 0,
    this.agentReviews = 0,
    this.agentTrips,
    this.agentVerified = false,
    this.title,
    this.inclusions = const [],
    this.timeline,
    this.notes,
    this.cancellationPolicy,
    this.refundTerms,
    this.expiresAt,
    this.acceptedAt,
    this.paymentDueAt,
  });

  final String id;
  final String requestId;
  final String agentId;

  /// Total price in INR.
  final double price;
  final BidStatus status;
  final String agentName;
  final double agentRating;
  final int agentReviews;

  /// Completed bookings, when the API includes it.
  final int? agentTrips;
  final bool agentVerified;
  final String? title;
  final List<String> inclusions;

  /// The agent's delivery promise ("Ticket within 2 hours").
  final String? timeline;
  final String? notes;

  /// Cancellation policy title and summary.
  final String? cancellationPolicy;
  final String? refundTerms;

  /// The offer is valid until then.
  final DateTime? expiresAt;
  final DateTime? acceptedAt;

  /// Pay before then or the accepted bid lapses.
  final DateTime? paymentDueAt;
  final DateTime createdAt;
}
