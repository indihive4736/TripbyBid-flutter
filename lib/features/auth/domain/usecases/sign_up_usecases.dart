import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/indian_phone.dart';
import '../entities/password_strength.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

final class SignUpParams {
  const SignUpParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.acceptedTerms,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final bool acceptedTerms;
}

/// Validates and creates a traveler account. `Ok(true)` means a code was
/// emailed and must be verified next.
class SignUpUseCase implements UseCase<bool, SignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<Result<bool>> call(SignUpParams params) async {
    final name = params.name.trim();
    if (name.length < 2 || name.length > 60) {
      return const Err(ValidationFailure('Enter your full name.'));
    }
    final email = params.email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(email)) {
      return const Err(ValidationFailure('Enter a valid email address.'));
    }
    final phone = IndianPhone.normalize(params.phone);
    if (phone == null) {
      return const Err(
        ValidationFailure('Enter a 10-digit Indian mobile number.'),
      );
    }
    final strength = PasswordStrength.of(params.password);
    if (!strength.isAcceptable) {
      return const Err(
        ValidationFailure(
          'Use 8+ characters with at least two of: a capital, a number, '
          'a symbol.',
        ),
      );
    }
    if (params.password.length > 72) {
      return const Err(ValidationFailure('Password is too long.'));
    }
    if (!params.acceptedTerms) {
      return const Err(
        ValidationFailure('Please accept the Terms and Privacy Policy.'),
      );
    }
    return _repository.signUp(
      name: name,
      email: email,
      phone: phone,
      password: params.password,
    );
  }
}

final class VerifyEmailParams {
  const VerifyEmailParams({required this.email, required this.code});

  final String email;
  final String code;
}

class VerifyEmailUseCase implements UseCase<User, VerifyEmailParams> {
  const VerifyEmailUseCase(this._repository);

  final AuthRepository _repository;

  static final _code = RegExp(r'^\d{6}$');

  @override
  Future<Result<User>> call(VerifyEmailParams params) async {
    if (!_code.hasMatch(params.code)) {
      return const Err(ValidationFailure('Enter the 6-digit code.'));
    }
    return _repository.verifyEmail(
      email: params.email.trim().toLowerCase(),
      code: params.code,
    );
  }
}

/// [params] is the email address.
class ResendCodeUseCase implements UseCase<void, String> {
  const ResendCodeUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) =>
      _repository.resendCode(params.trim().toLowerCase());
}
