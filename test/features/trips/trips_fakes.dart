import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/trips/domain/entities/bid.dart';
import 'package:tripbybid/features/trips/domain/entities/booking.dart';
import 'package:tripbybid/features/trips/domain/entities/new_trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_detail.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/repositories/trips_repository.dart';

const _notScripted = Err<Never>(ServerFailure('not scripted'));

/// In-memory [TripsRepository]. Script answers through the `*Result`
/// fields; calls are recorded in [calls] as `method:arg`.
class FakeTripsRepository implements TripsRepository {
  Result<List<TripRequest>> myTripsResult = const Ok([]);
  Result<TripDetail> detailResult = _notScripted;
  Result<List<Bid>> activeBidsResult = const Ok([]);
  Result<TripRequest> createResult = _notScripted;
  Result<TripRequest> updateResult = _notScripted;
  Result<void> cancelTripResult = const Ok(null);
  Result<Bid> acceptResult = _notScripted;
  Result<Bid> releaseResult = _notScripted;
  Result<CancellationQuote> quoteResult = _notScripted;
  Result<Booking> cancelBookingResult = _notScripted;
  Result<void> verifyResult = const Ok(null);
  Result<void> correctionResult = const Ok(null);
  Result<void> supportResult = const Ok(null);
  Result<void> rateResult = const Ok(null);

  final calls = <String>[];
  NewTripRequest? lastCreated;

  @override
  Future<Result<List<TripRequest>>> getMyTrips() async {
    calls.add('getMyTrips');
    return myTripsResult;
  }

  @override
  Future<Result<TripDetail>> getTripDetail(String requestId) async {
    calls.add('getTripDetail:$requestId');
    return detailResult;
  }

  @override
  Future<Result<List<Bid>>> getActiveBids(String requestId) async {
    calls.add('getActiveBids:$requestId');
    return activeBidsResult;
  }

  @override
  Future<Result<TripRequest>> createTrip(NewTripRequest request) async {
    calls.add('createTrip');
    lastCreated = request;
    return createResult;
  }

  @override
  Future<Result<TripRequest>> updateTrip(
    String requestId, {
    double? budget,
    String? requirements,
  }) async {
    calls.add('updateTrip:$requestId');
    return updateResult;
  }

  @override
  Future<Result<void>> cancelTrip(String requestId) async {
    calls.add('cancelTrip:$requestId');
    return cancelTripResult;
  }

  @override
  Future<Result<Bid>> acceptBid(String bidId) async {
    calls.add('acceptBid:$bidId');
    return acceptResult;
  }

  @override
  Future<Result<Bid>> releaseBid(String bidId) async {
    calls.add('releaseBid:$bidId');
    return releaseResult;
  }

  @override
  Future<Result<CancellationQuote>> getCancellationQuote(
    String bookingId,
  ) async {
    calls.add('getCancellationQuote:$bookingId');
    return quoteResult;
  }

  @override
  Future<Result<Booking>> cancelBooking(
    String bookingId, {
    required double expectedRefund,
    String? reason,
  }) async {
    calls.add('cancelBooking:$bookingId:$expectedRefund');
    return cancelBookingResult;
  }

  @override
  Future<Result<void>> verifyTicket(String bookingId) async {
    calls.add('verifyTicket:$bookingId');
    return verifyResult;
  }

  @override
  Future<Result<void>> requestCorrection(
    String bookingId, {
    required List<String> reasons,
    String? details,
  }) async {
    calls.add('requestCorrection:$bookingId');
    return correctionResult;
  }

  @override
  Future<Result<void>> raiseSupportTicket(
    String bookingId, {
    required String description,
  }) async {
    calls.add('raiseSupportTicket:$bookingId');
    return supportResult;
  }

  @override
  Future<Result<void>> rateAgent({
    required String bookingId,
    required String agentId,
    required int rating,
    String? comment,
  }) async {
    calls.add('rateAgent:$bookingId:$rating');
    return rateResult;
  }
}

/// Builders for trip entities with sensible defaults.
abstract final class TripFixtures {
  static TripRequest request({
    String id = 'a9c3e05f-0000-4000-8000-000000000001',
    TripType type = TripType.flight,
    String status = 'bidding',
    int bidsCount = 0,
    double budget = 20000,
    DateTime? departDate,
    List<Bid> bids = const [],
    Booking? booking,
  }) => TripRequest(
    id: id,
    type: type,
    fromLocation: 'Mumbai (BOM)',
    toLocation: 'Dubai (DXB)',
    departDate: departDate ?? DateTime(2026, 11, 12),
    budget: budget,
    status: status,
    bidsCount: bidsCount,
    createdAt: DateTime(2026, 10, 1, 10, 12),
    bids: bids,
    booking: booking,
  );

  static Bid bid({
    String id = 'bid-1',
    double price = 17999,
    BidStatus status = BidStatus.active,
    String agentName = 'AirTrek India',
    DateTime? paymentDueAt,
  }) => Bid(
    id: id,
    requestId: 'a9c3e05f-0000-4000-8000-000000000001',
    agentId: 'agent-$id',
    price: price,
    status: status,
    agentName: agentName,
    agentRating: 4.9,
    agentTrips: 312,
    agentVerified: true,
    inclusions: const ['Emirates', 'Non-stop', '30 kg'],
    paymentDueAt: paymentDueAt,
    createdAt: DateTime(2026, 10, 1, 10, 19),
  );

  static Booking booking({
    String id = 'booking-1',
    String status = 'confirmed',
    double price = 17999,
  }) => Booking(
    id: id,
    requestId: 'a9c3e05f-0000-4000-8000-000000000001',
    status: status,
    price: price,
    platformFee: 300,
    paymentStatus: 'paid',
    paymentId: 'pay-1',
    createdAt: DateTime(2026, 10, 1, 11, 5),
    agent: const AgentProfile(
      id: 'agent-bid-1',
      name: 'Ravi',
      agencyName: 'AirTrek India',
      rating: 4.9,
      verified: true,
    ),
  );
}
