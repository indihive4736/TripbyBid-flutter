part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Still checking the stored session (splash screen).
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}
