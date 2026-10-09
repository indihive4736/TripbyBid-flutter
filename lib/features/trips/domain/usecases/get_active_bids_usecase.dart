import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bid.dart';
import '../repositories/trips_repository.dart';

/// Live offers on a request, cheapest first. [call]'s param is the request id.
class GetActiveBidsUseCase implements UseCase<List<Bid>, String> {
  const GetActiveBidsUseCase(this._repository);

  final TripsRepository _repository;

  @override
  Future<Result<List<Bid>>> call(String params) =>
      _repository.getActiveBids(params);
}
