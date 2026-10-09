import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trip_detail.dart';
import '../entities/trip_request.dart';
import '../repositories/trips_repository.dart';

class GetMyTripsUseCase implements UseCase<List<TripRequest>, NoParams> {
  const GetMyTripsUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<List<TripRequest>>> call(NoParams params) =>
      _repository.getMyTrips();
}

class GetTripDetailUseCase implements UseCase<TripDetail, String> {
  const GetTripDetailUseCase(this._repository);

  final TripsRepository _repository;

  /// [params] is the request id.
  @override
  Future<Result<TripDetail>> call(String params) =>
      _repository.getTripDetail(params);
}
