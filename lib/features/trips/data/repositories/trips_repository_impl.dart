import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/bid.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_detail.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/entities/trip_stage.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_remote_data_source.dart';

class TripsRepositoryImpl implements TripsRepository {
  const TripsRepositoryImpl(this._remote);

  final TripsRemoteDataSource _remote;

  @override
  Future<Result<List<TripRequest>>> getMyTrips() => guard(_remote.getMyTrips);

  @override
  Future<Result<TripDetail>> getTripDetail(String requestId) => guard(() async {
    final request = await _remote.getRequest(requestId);
    final stage = request.stage;
    // Live offers exist only before booking; the booking only after.
    // Future.wait settles both before rethrowing the first AppException,
    // so neither failure goes unhandled.
    final [bids, booking] = await Future.wait<Object?>([
      if (stage.isBidding || stage == TripStage.paymentDue)
        _remote.getActiveBids(requestId)
      else
        Future.value(const <Bid>[]),
      if (stage.isBooked || stage == TripStage.cancelled)
        _remote.getBookingForRequest(requestId)
      else
        Future.value(request.booking),
    ]);
    return TripDetail(
      request: request,
      activeBids: bids! as List<Bid>,
      booking: booking as Booking?,
    );
  });

  @override
  Future<Result<List<Bid>>> getActiveBids(String requestId) =>
      guard(() => _remote.getActiveBids(requestId));

  @override
  Future<Result<TripRequest>> createTrip(NewTripRequest request) =>
      guard(() => _remote.createRequest(request));

  @override
  Future<Result<TripRequest>> updateTrip(
    String requestId, {
    double? budget,
    String? requirements,
  }) => guard(
    () => _remote.updateRequest(
      requestId,
      budget: budget,
      requirements: requirements,
    ),
  );

  @override
  Future<Result<void>> cancelTrip(String requestId) =>
      guard(() => _remote.deleteRequest(requestId));

  @override
  Future<Result<Bid>> acceptBid(String bidId) =>
      guard(() => _remote.acceptBid(bidId));

  @override
  Future<Result<Bid>> releaseBid(String bidId) =>
      guard(() => _remote.releaseBid(bidId));

  @override
  Future<Result<CancellationQuote>> getCancellationQuote(String bookingId) =>
      guard(() => _remote.getCancellationQuote(bookingId));

  @override
  Future<Result<Booking>> cancelBooking(
    String bookingId, {
    required double expectedRefund,
    String? reason,
  }) => guard(
    () => _remote.cancelBooking(
      bookingId,
      expectedRefund: expectedRefund,
      reason: reason,
    ),
  );

  @override
  Future<Result<void>> verifyTicket(String bookingId) =>
      guard(() => _remote.verifyTicket(bookingId));

  @override
  Future<Result<void>> requestCorrection(
    String bookingId, {
    required List<String> reasons,
    String? details,
  }) => guard(
    () => _remote.requestCorrection(
      bookingId,
      reasons: reasons,
      details: details,
    ),
  );

  @override
  Future<Result<void>> raiseSupportTicket(
    String bookingId, {
    required String description,
  }) => guard(
    () => _remote.raiseSupportTicket(bookingId, description: description),
  );

  @override
  Future<Result<void>> rateAgent({
    required String bookingId,
    required String agentId,
    required int rating,
    String? comment,
  }) => guard(
    () => _remote.createReview(
      bookingId: bookingId,
      agentId: agentId,
      rating: rating,
      comment: comment,
    ),
  );
}
