part of 'login_cubit.dart';

enum LoginStatus { initial, submitting, success, failure }

final class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.errorMessage,
  });

  final LoginStatus status;

  /// Set when [status] is [LoginStatus.success].
  final User? user;

  /// Set when [status] is [LoginStatus.failure].
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
