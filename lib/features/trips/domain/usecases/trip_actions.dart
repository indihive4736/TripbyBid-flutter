import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bid.dart';
import '../entities/booking.dart';
import '../entities/trip_detail.dart';
import '../entities/trip_request.dart';
import '../repositories/trips_repository.dart';

final class UpdateTripParams {
  const UpdateTripParams(this.requestId, {this.budget, this.requirements});

  final String requestId;
  final double? budget;
  final String? requirements;
}

class UpdateTripUseCase implements UseCase<TripRequest, UpdateTripParams> {
  const UpdateTripUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<TripRequest>> call(UpdateTripParams params) async {
    if (params.budget != null && params.budget! <= 0) {
      return const Err(ValidationFailure('Set a budget above ₹0.'));
    }
    return _repository.updateTrip(
      params.requestId,
      budget: params.budget,
      requirements: params.requirements,
    );
  }
}

/// Withdraws a request that is not booked yet. [params] is the request id.
class CancelTripUseCase implements UseCase<void, String> {
  const CancelTripUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.cancelTrip(params);
}

/// [params] is the bid id.
class AcceptBidUseCase implements UseCase<Bid, String> {
  const AcceptBidUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<Bid>> call(String params) => _repository.acceptBid(params);
}

/// [params] is the bid id.
class ReleaseBidUseCase implements UseCase<Bid, String> {
  const ReleaseBidUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<Bid>> call(String params) => _repository.releaseBid(params);
}

/// [params] is the booking id.
class GetCancellationQuoteUseCase
    implements UseCase<CancellationQuote, String> {
  const GetCancellationQuoteUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<CancellationQuote>> call(String params) =>
      _repository.getCancellationQuote(params);
}

final class CancelBookingParams {
  const CancelBookingParams({
    required this.bookingId,
    required this.expectedRefund,
    this.reason,
  });

  final String bookingId;

  /// The refund the traveler saw; the backend refuses if it changed.
  final double expectedRefund;
  final String? reason;
}

class CancelBookingUseCase implements UseCase<Booking, CancelBookingParams> {
  const CancelBookingUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<Booking>> call(CancelBookingParams params) =>
      _repository.cancelBooking(
        params.bookingId,
        expectedRefund: params.expectedRefund,
        reason: params.reason,
      );
}

/// [params] is the booking id.
class VerifyTicketUseCase implements UseCase<void, String> {
  const VerifyTicketUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.verifyTicket(params);
}

final class CorrectionParams {
  const CorrectionParams(this.bookingId, {required this.reasons, this.details});

  final String bookingId;
  final List<String> reasons;
  final String? details;
}

class RequestCorrectionUseCase implements UseCase<void, CorrectionParams> {
  const RequestCorrectionUseCase(this._repository);

  final TripsRepository _repository;

  /// Ticket problems travelers can report (same list as the web app).
  static const reasons = [
    'Name spelled incorrectly',
    'Wrong travel date',
    'Wrong flight number',
    'Wrong departure/arrival time',
    'Wrong class/seat',
    'Missing passenger',
    'Wrong route/destination',
  ];

  @override
  Future<Result<void>> call(CorrectionParams params) async {
    if (params.reasons.isEmpty) {
      return const Err(
        ValidationFailure('Pick what is wrong with the ticket.'),
      );
    }
    return _repository.requestCorrection(
      params.bookingId,
      reasons: params.reasons,
      details: params.details,
    );
  }
}

final class SupportTicketParams {
  const SupportTicketParams(this.bookingId, {required this.description});

  final String bookingId;
  final String description;
}

class RaiseSupportTicketUseCase implements UseCase<void, SupportTicketParams> {
  const RaiseSupportTicketUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<void>> call(SupportTicketParams params) async {
    if (params.description.trim().length < 10) {
      return const Err(
        ValidationFailure('Tell us a little more (at least 10 characters).'),
      );
    }
    return _repository.raiseSupportTicket(
      params.bookingId,
      description: params.description.trim(),
    );
  }
}

final class RateAgentParams {
  const RateAgentParams({
    required this.bookingId,
    required this.agentId,
    required this.rating,
    this.comment,
  });

  final String bookingId;
  final String agentId;
  final int rating;
  final String? comment;
}

class RateAgentUseCase implements UseCase<void, RateAgentParams> {
  const RateAgentUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<void>> call(RateAgentParams params) async {
    if (params.rating < 1 || params.rating > 5) {
      return const Err(ValidationFailure('Tap a star to rate.'));
    }
    final comment = params.comment?.trim();
    return _repository.rateAgent(
      bookingId: params.bookingId,
      agentId: params.agentId,
      rating: params.rating,
      comment: comment == null || comment.isEmpty ? null : comment,
    );
  }
}
