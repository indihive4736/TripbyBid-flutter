part of 'login_cubit.dart';

enum LoginStatus { initial, submitting, success, failure }

final class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.errorMessage,
    this.emailNotVerified = false,
    this.email,
  });

  final LoginStatus status;

  /// Set when [status] is [LoginStatus.success].
  final User? user;

  /// Set when [status] is [LoginStatus.failure].
  final String? errorMessage;

  /// The failure was an unverified email: the screen should move on to the
  /// code entry for [email].
  final bool emailNotVerified;

  /// The address to verify, set with [emailNotVerified].
  final String? email;

  @override
  List<Object?> get props => [
    status,
    user,
    errorMessage,
    emailNotVerified,
    email,
  ];
}
