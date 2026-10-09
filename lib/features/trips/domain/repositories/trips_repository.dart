import '../../../../core/error/result.dart';
import '../entities/bid.dart';
import '../entities/booking.dart';
import '../entities/new_trip_request.dart';
import '../entities/trip_detail.dart';
import '../entities/trip_request.dart';

abstract interface class TripsRepository {
  /// The traveler's requests, newest first, with their bookings embedded.
  Future<Result<List<TripRequest>>> getMyTrips();

  /// The request, its live bids and its booking (if paid).
  Future<Result<TripDetail>> getTripDetail(String requestId);

  /// Live offers on a request, cheapest first.
  Future<Result<List<Bid>>> getActiveBids(String requestId);

  Future<Result<TripRequest>> createTrip(NewTripRequest request);

  /// Edit the budget or notes (only before any bid arrives, except notes).
  Future<Result<TripRequest>> updateTrip(
    String requestId, {
    double? budget,
    String? requirements,
  });

  /// Withdraw a request that is not booked yet.
  Future<Result<void>> cancelTrip(String requestId);

  /// Hold this offer; payment becomes due at [Bid.paymentDueAt].
  Future<Result<Bid>> acceptBid(String bidId);

  /// Give up an accepted offer so another can be accepted.
  Future<Result<Bid>> releaseBid(String bidId);

  Future<Result<CancellationQuote>> getCancellationQuote(String bookingId);

  /// Cancel a paid booking at the quoted refund.
  Future<Result<Booking>> cancelBooking(
    String bookingId, {
    required double expectedRefund,
    String? reason,
  });

  /// Confirm the uploaded ticket is correct (completes the booking).
  Future<Result<void>> verifyTicket(String bookingId);

  Future<Result<void>> requestCorrection(
    String bookingId, {
    required List<String> reasons,
    String? details,
  });

  Future<Result<void>> raiseSupportTicket(
    String bookingId, {
    required String description,
  });

  /// Rate the agent after a completed trip.
  Future<Result<void>> rateAgent({
    required String bookingId,
    required String agentId,
    required int rating,
    String? comment,
  });
}
