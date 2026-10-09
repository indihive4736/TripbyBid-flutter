import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/new_trip_request.dart';
import '../entities/trip_request.dart';
import '../repositories/trips_repository.dart';

/// Validates and posts a new request so agents can bid on it.
class PostTripRequestUseCase implements UseCase<TripRequest, NewTripRequest> {
  PostTripRequestUseCase(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TripsRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<Result<TripRequest>> call(NewTripRequest params) async {
    final problem = validate(params);
    if (problem != null) return Err(ValidationFailure(problem));
    return _repository.createTrip(params);
  }

  /// The first rule [request] breaks, or null when it can be posted.
  String? validate(NewTripRequest request) {
    final isHotel = request.type == TripType.hotel;
    if (request.from.name.trim().isEmpty) {
      return isHotel ? 'Choose a city.' : 'Choose where you are leaving from.';
    }
    if (!isHotel && request.to.name.trim().isEmpty) {
      return 'Choose your destination.';
    }
    if (!isHotel && request.from == request.to) {
      return 'Origin and destination must be different.';
    }

    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    if (_day(request.departDate).isBefore(today)) {
      return isHotel
          ? 'Check-in cannot be in the past.'
          : 'Travel date cannot be in the past.';
    }
    final returnDate = request.returnDate;
    if (isHotel) {
      if (returnDate == null) return 'Choose a check-out date.';
      if (!_day(returnDate).isAfter(_day(request.departDate))) {
        return 'Check-out must be after check-in.';
      }
    } else if (request.type == TripType.flight &&
        request.tripType == 'round-trip') {
      if (returnDate == null) return 'Choose a return date.';
      if (_day(returnDate).isBefore(_day(request.departDate))) {
        return 'Return cannot be before departure.';
      }
    }

    if (request.adults < 1) return 'At least one adult must travel.';
    if (isHotel && request.rooms < 1) return 'Book at least one room.';
    if (request.budget <= 0) return 'Set a budget above ₹0.';
    if (request.contactPhone.trim().isEmpty) {
      return 'Add a phone number so agents can reach you.';
    }
    return null;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
