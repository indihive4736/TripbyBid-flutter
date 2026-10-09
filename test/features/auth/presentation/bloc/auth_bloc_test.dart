import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/logout_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/watch_session_ended_usecase.dart';
import 'package:tripbybid/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  AuthBloc build() => AuthBloc(
    getCurrentUser: GetCurrentUserUseCase(repository),
    logout: LogoutUseCase(repository),
    watchSessionEnded: WatchSessionEndedUseCase(repository),
  );

  test('starts unknown', () => expect(build().state, const AuthUnknown()));

  blocTest<AuthBloc, AuthState>(
    'AuthStarted with a stored session → Authenticated',
    setUp: () => repository.currentUserResult = const Ok(tUser),
    build: build,
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const Authenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted without a session → Unauthenticated',
    build: build,
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted failing → Unauthenticated',
    setUp: () => repository.currentUserResult = const Err(NetworkFailure()),
    build: build,
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthLoggedIn → Authenticated',
    build: build,
    act: (bloc) => bloc.add(const AuthLoggedIn(tUser)),
    expect: () => [const Authenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthLogoutRequested logs out → Unauthenticated',
    build: build,
    seed: () => const Authenticated(tUser),
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => [const Unauthenticated()],
    verify: (_) => expect(repository.calls, ['logout']),
  );

  blocTest<AuthBloc, AuthState>(
    'a session that ends on its own signs out with sessionExpired',
    build: build,
    seed: () => const Authenticated(tUser),
    act: (_) => repository.endSession(),
    expect: () => [const Unauthenticated(sessionExpired: true)],
  );
}
