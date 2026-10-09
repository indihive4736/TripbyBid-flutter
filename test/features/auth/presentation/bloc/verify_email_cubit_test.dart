import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/sign_up_usecases.dart';
import 'package:tripbybid/features/auth/presentation/bloc/verify_email_cubit.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  VerifyEmailCubit build({int cooldown = 30}) => VerifyEmailCubit(
    verifyEmail: VerifyEmailUseCase(repository),
    resendCode: ResendCodeUseCase(repository),
    resendCooldown: cooldown,
    tick: const Duration(milliseconds: 10),
  );

  const start = VerifyEmailState(email: 'asha@example.com');

  void typeAll(VerifyEmailCubit cubit, String digits) {
    for (final d in digits.split('')) {
      cubit.digit(d);
    }
  }

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'keypad digits fill the code; backspace removes the last one',
    build: build,
    seed: () => start,
    act: (cubit) => cubit
      ..digit('4')
      ..digit('x')
      ..digit('8')
      ..backspace(),
    expect: () => [
      start.copyWith(code: '4'),
      start.copyWith(code: '48'),
      start.copyWith(code: '4'),
    ],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'the sixth digit auto-submits and success carries the user',
    setUp: () => repository.verifyResult = const Ok(tUser),
    build: build,
    seed: () => start,
    act: (cubit) => typeAll(cubit, '482190'),
    skip: 5,
    expect: () => [
      start.copyWith(code: '482190'),
      start.copyWith(code: '482190', status: VerifyStatus.verifying),
      start.copyWith(code: '482190', status: VerifyStatus.success, user: tUser),
    ],
    verify: (_) => expect(repository.calls, ['verify:asha@example.com:482190']),
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'a rejected code shows the error; the next digit starts over',
    setUp: () => repository.verifyResult = const Err(
      ServerFailure('Invalid or expired code.'),
    ),
    build: build,
    seed: () => start,
    act: (cubit) async {
      cubit.paste('Your code: 111 222');
      await Future<void>.delayed(Duration.zero);
      cubit.digit('7');
    },
    expect: () => [
      start.copyWith(code: '111222'),
      start.copyWith(code: '111222', status: VerifyStatus.verifying),
      start.copyWith(
        code: '111222',
        status: VerifyStatus.failure,
        errorMessage: 'Invalid or expired code.',
      ),
      start.copyWith(code: '7'),
    ],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'input is ignored while verifying',
    build: build,
    seed: () => start.copyWith(code: '123456', status: VerifyStatus.verifying),
    act: (cubit) => cubit
      ..digit('1')
      ..backspace()
      ..paste('999999'),
    expect: () => <VerifyEmailState>[],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'start counts down to zero, then a resend restarts the countdown',
    build: () => build(cooldown: 2),
    act: (cubit) async {
      cubit.start('asha@example.com');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cubit.state.canResend, isTrue);
      await cubit.resend();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    },
    expect: () => [
      start,
      start.copyWith(resendIn: 2),
      start.copyWith(resendIn: 1),
      start.copyWith(resendIn: 0),
      start.copyWith(resendStatus: ResendStatus.sending),
      start.copyWith(resendStatus: ResendStatus.sent),
      start.copyWith(resendStatus: ResendStatus.sent, resendIn: 2),
      start.copyWith(resendStatus: ResendStatus.sent, resendIn: 1),
      start.copyWith(resendStatus: ResendStatus.sent, resendIn: 0),
    ],
    verify: (_) => expect(repository.calls, ['resend:asha@example.com']),
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'resend is refused during the countdown',
    build: build,
    seed: () => start.copyWith(resendIn: 12),
    act: (cubit) => cubit.resend(),
    expect: () => <VerifyEmailState>[],
    verify: (_) => expect(repository.calls, isEmpty),
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'a failed resend reports its error',
    setUp: () => repository.resendResult = const Err(NetworkFailure()),
    build: build,
    seed: () => start,
    act: (cubit) => cubit.resend(),
    expect: () => [
      start.copyWith(resendStatus: ResendStatus.sending),
      start.copyWith(
        resendStatus: ResendStatus.failed,
        resendError: const NetworkFailure().message,
      ),
    ],
  );
}
