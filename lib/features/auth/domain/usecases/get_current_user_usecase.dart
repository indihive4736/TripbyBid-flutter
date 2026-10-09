import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Restores the session on app start. `Ok(null)` means signed out.
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<User?>> call(NoParams params) => _repository.getCurrentUser();
}
