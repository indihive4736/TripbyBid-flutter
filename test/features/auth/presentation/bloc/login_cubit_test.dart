import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/login_usecase.dart';
import 'package:tripbybid/features/auth/presentation/bloc/login_cubit.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockLoginUseCase login;

  setUpAll(provideResultDummies);

  setUp(() => login = MockLoginUseCase());

  const params = LoginParams(email: 'asha@example.com', password: 'secret');

  blocTest<LoginCubit, LoginState>(
    'emits submitting then success with the user',
    setUp: () => when(login(params)).thenAnswer((_) async => const Ok(tUser)),
    build: () => LoginCubit(login: login),
    act: (cubit) =>
        cubit.submit(email: params.email, password: params.password),
    expect: () => [
      const LoginState(status: LoginStatus.submitting),
      const LoginState(status: LoginStatus.success, user: tUser),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'emits submitting then failure with the failure message',
    setUp: () => when(login(any)).thenAnswer(
      (_) async => const Err(UnauthorizedFailure('Invalid credentials')),
    ),
    build: () => LoginCubit(login: login),
    act: (cubit) => cubit.submit(email: params.email, password: 'wrong'),
    expect: () => [
      const LoginState(status: LoginStatus.submitting),
      const LoginState(
        status: LoginStatus.failure,
        errorMessage: 'Invalid credentials',
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'ignores a submit while one is in flight',
    build: () => LoginCubit(login: login),
    seed: () => const LoginState(status: LoginStatus.submitting),
    act: (cubit) =>
        cubit.submit(email: params.email, password: params.password),
    expect: () => <LoginState>[],
    verify: (_) => verifyZeroInteractions(login),
  );
}
