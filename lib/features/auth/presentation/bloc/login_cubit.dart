import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/sign_up_usecases.dart';

part 'login_state.dart';

/// Submission state of the login form.
class LoginCubit extends Cubit<LoginState> {
  /// With [resendCode], an unverified account gets a fresh signup code
  /// before the screen moves on to code entry.
  LoginCubit({required LoginUseCase login, ResendCodeUseCase? resendCode})
    : _login = login,
      _resendCode = resendCode,
      super(const LoginState());

  final LoginUseCase _login;
  final ResendCodeUseCase? _resendCode;

  static const codeResentMessage =
      'Your email isn’t verified yet — we sent you a new code.';

  Future<void> submit({required String email, required String password}) async {
    if (state.status == LoginStatus.submitting) return;
    emit(const LoginState(status: LoginStatus.submitting));
    final result = await _login(LoginParams(email: email, password: password));
    switch (result) {
      case Ok(:final value):
        emit(LoginState(status: LoginStatus.success, user: value));
      case Err(failure: EmailNotVerifiedFailure(:final message)):
        final address = email.trim().toLowerCase();
        final resent = switch (await _resendCode?.call(address)) {
          Ok() => true,
          Err() || null => false,
        };
        emit(
          LoginState(
            status: LoginStatus.failure,
            errorMessage: resent ? codeResentMessage : message,
            emailNotVerified: true,
            email: address,
          ),
        );
      case Err(:final failure):
        emit(
          LoginState(
            status: LoginStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
