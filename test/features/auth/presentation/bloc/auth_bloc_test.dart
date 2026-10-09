import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/core/usecase/usecase.dart';
import 'package:tripbybid/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockGetCurrentUserUseCase getCurrentUser;
  late MockLogoutUseCase logout;

  setUpAll(provideResultDummies);

  setUp(() {
    getCurrentUser = MockGetCurrentUserUseCase();
    logout = MockLogoutUseCase();
  });

  AuthBloc build() => AuthBloc(getCurrentUser: getCurrentUser, logout: logout);

  test('starts unknown', () => expect(build().state, const AuthUnknown()));

  blocTest<AuthBloc, AuthState>(
    'AuthStarted with a stored session → Authenticated',
    setUp: () =>
        when(getCurrentUser(any)).thenAnswer((_) async => const Ok(tUser)),
    build: build,
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const Authenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted without a session → Unauthenticated',
    setUp: () =>
        when(getCurrentUser(any)).thenAnswer((_) async => const Ok(null)),
    build: build,
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted failing → Unauthenticated',
    setUp: () => when(
      getCurrentUser(any),
    ).thenAnswer((_) async => const Err(NetworkFailure())),
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
    setUp: () => when(logout(any)).thenAnswer((_) async => const Ok(null)),
    build: build,
    seed: () => const Authenticated(tUser),
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    expect: () => [const Unauthenticated()],
    verify: (_) => verify(logout(const NoParams())).called(1),
  );
}
