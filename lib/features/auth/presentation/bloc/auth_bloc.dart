import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-wide session status. The router redirects on its state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetCurrentUserUseCase getCurrentUser,
    required LogoutUseCase logout,
  }) : _getCurrentUser = getCurrentUser,
       _logout = logout,
       super(const AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final result = await _getCurrentUser(const NoParams());
    emit(switch (result) {
      Ok(value: final User user) => Authenticated(user),
      Ok() || Err() => const Unauthenticated(),
    });
  }

  void _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) =>
      emit(Authenticated(event.user));

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    emit(const Unauthenticated());
  }
}
