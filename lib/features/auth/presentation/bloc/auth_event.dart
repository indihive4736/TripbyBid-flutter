part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App start: restore the stored session.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Login or email verification succeeded.
final class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// The session expired or was revoked while the app was in use.
final class AuthSessionEnded extends AuthEvent {
  const AuthSessionEnded();
}
