import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';

part 'login_state.dart';

/// Submission state of the login form.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required LoginUseCase login})
    : _login = login,
      super(const LoginState());

  final LoginUseCase _login;

  Future<void> submit({required String email, required String password}) async {
    if (state.status == LoginStatus.submitting) return;
    emit(const LoginState(status: LoginStatus.submitting));
    final result = await _login(LoginParams(email: email, password: password));
    emit(switch (result) {
      Ok(:final value) => LoginState(status: LoginStatus.success, user: value),
      Err(:final failure) => LoginState(
        status: LoginStatus.failure,
        errorMessage: failure.message,
      ),
    });
  }
}
