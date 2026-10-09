import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

final class LoginParams {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) =>
      other is LoginParams &&
      other.email == email &&
      other.password == password;

  @override
  int get hashCode => Object.hash(email, password);
}

class LoginUseCase implements UseCase<User, LoginParams> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<Result<User>> call(LoginParams params) async {
    final email = params.email.trim();
    if (!_emailPattern.hasMatch(email)) {
      return const Err(ValidationFailure('Enter a valid email address.'));
    }
    if (params.password.isEmpty) {
      return const Err(ValidationFailure('Enter your password.'));
    }
    return _repository.login(email: email, password: params.password);
  }
}
