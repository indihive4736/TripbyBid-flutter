import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/login_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/sign_up_usecases.dart';
import 'package:tripbybid/features/auth/presentation/bloc/login_cubit.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  LoginCubit build() => LoginCubit(login: LoginUseCase(repository));

  LoginCubit buildWithResend() => LoginCubit(
    login: LoginUseCase(repository),
    resendCode: ResendCodeUseCase(repository),
  );

  blocTest<LoginCubit, LoginState>(
    'emits submitting then success with the user',
    setUp: () => repository.loginResult = const Ok(tUser),
    build: build,
    act: (cubit) => cubit.submit(email: 'asha@example.com', password: 'secret'),
    expect: () => [
      const LoginState(status: LoginStatus.submitting),
      const LoginState(status: LoginStatus.success, user: tUser),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'emits submitting then failure with the failure message',
    setUp: () => repository.loginResult = const Err(
      UnauthorizedFailure('Email or password is incorrect.'),
    ),
    build: build,
    act: (cubit) => cubit.submit(email: 'asha@example.com', password: 'wrong'),
    expect: () => [
      const LoginState(status: LoginStatus.submitting),
      const LoginState(
        status: LoginStatus.failure,
        errorMessage: 'Email or password is incorrect.',
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'ignores a submit while one is in flight',
    build: build,
    seed: () => const LoginState(status: LoginStatus.submitting),
    act: (cubit) => cubit.submit(email: 'asha@example.com', password: 'secret'),
    expect: () => <LoginState>[],
    verify: (_) => expect(repository.calls, isEmpty),
  );

  blocTest<LoginCubit, LoginState>(
    'an unverified email resends the code and flags code entry',
    setUp: () => repository.loginResult = const Err(EmailNotVerifiedFailure()),
    build: buildWithResend,
    act: (cubit) =>
        cubit.submit(email: ' Asha@Example.com ', password: 'secret'),
    expect: () => [
      const LoginState(status: LoginStatus.submitting),
      const LoginState(
        status: LoginStatus.failure,
        errorMessage: LoginCubit.codeResentMessage,
        emailNotVerified: true,
        email: 'asha@example.com',
      ),
    ],
    verify: (_) => expect(repository.calls, [
      'login:Asha@Example.com',
      'resend:asha@example.com',
    ]),
  );

  blocTest<LoginCubit, LoginState>(
    'an unverified email still flags code entry when the resend fails',
    setUp: () {
      repository
        ..loginResult = const Err(EmailNotVerifiedFailure())
        ..resendResult = const Err(NetworkFailure());
    },
    build: buildWithResend,
    act: (cubit) => cubit.submit(email: 'asha@example.com', password: 'x'),
    skip: 1,
    expect: () => [
      LoginState(
        status: LoginStatus.failure,
        errorMessage: const EmailNotVerifiedFailure().message,
        emailNotVerified: true,
        email: 'asha@example.com',
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'without a resend use case an unverified email still flags code entry',
    setUp: () => repository.loginResult = const Err(EmailNotVerifiedFailure()),
    build: build,
    act: (cubit) => cubit.submit(email: 'asha@example.com', password: 'x'),
    skip: 1,
    expect: () => [
      LoginState(
        status: LoginStatus.failure,
        errorMessage: const EmailNotVerifiedFailure().message,
        emailNotVerified: true,
        email: 'asha@example.com',
      ),
    ],
    verify: (_) => expect(repository.calls, ['login:asha@example.com']),
  );
}
