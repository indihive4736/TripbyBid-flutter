import '../error/result.dart';

/// One application action. Implementations live in `features/*/domain/usecases`
/// and depend only on repository interfaces.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Parameters for a use case that takes none.
final class NoParams {
  const NoParams();
}
