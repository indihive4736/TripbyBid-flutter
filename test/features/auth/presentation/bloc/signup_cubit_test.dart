import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:tripbybid/features/auth/domain/usecases/sign_up_usecases.dart';
import 'package:tripbybid/features/auth/presentation/bloc/signup_cubit.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  SignupCubit build() => SignupCubit(
    signUp: SignUpUseCase(repository),
    getCurrentUser: GetCurrentUserUseCase(repository),
  );

  const filled = SignupState(
    name: 'Asha Rao',
    email: 'Asha@Example.com',
    phone: '9810043210',
    password: 'Travel#2026',
    acceptedTerms: true,
  );

  group('SignupState.isValid', () {
    test('true for a complete form', () => expect(filled.isValid, isTrue));

    test('needs every rule', () {
      expect(filled.copyWith(name: 'A').isValid, isFalse);
      expect(filled.copyWith(email: 'asha@').isValid, isFalse);
      expect(filled.copyWith(phone: '12345').isValid, isFalse);
      expect(filled.copyWith(password: 'travel').isValid, isFalse);
      expect(filled.copyWith(acceptedTerms: false).isValid, isFalse);
    });

    test('canSubmit is false while submitting', () {
      expect(
        filled.copyWith(status: SignupStatus.submitting).canSubmit,
        isFalse,
      );
    });
  });

  blocTest<SignupCubit, SignupState>(
    'field edits update the state and the live strength',
    build: build,
    act: (cubit) => cubit
      ..nameChanged('Asha Rao')
      ..passwordChanged('Travel')
      ..termsToggled(),
    expect: () => [
      const SignupState(name: 'Asha Rao'),
      const SignupState(name: 'Asha Rao', password: 'Travel'),
      const SignupState(
        name: 'Asha Rao',
        password: 'Travel',
        acceptedTerms: true,
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.strength.score, 1);
      expect(cubit.state.strength.label, 'Weak');
    },
  );

  blocTest<SignupCubit, SignupState>(
    'submit does nothing while the form is invalid',
    build: build,
    act: (cubit) => cubit.submit(),
    expect: () => <SignupState>[],
    verify: (_) => expect(repository.calls, isEmpty),
  );

  blocTest<SignupCubit, SignupState>(
    'a sent code → codeSent with the normalised email',
    build: build,
    seed: () => filled,
    act: (cubit) => cubit.submit(),
    expect: () => [
      filled.copyWith(status: SignupStatus.submitting),
      filled.copyWith(email: 'asha@example.com', status: SignupStatus.codeSent),
    ],
    verify: (_) =>
        expect(repository.calls, ['signUp:asha@example.com:+919810043210']),
  );

  blocTest<SignupCubit, SignupState>(
    'already signed in → loads the user → signedIn',
    setUp: () {
      repository
        ..signUpResult = const Ok(false)
        ..currentUserResult = const Ok(tUser);
    },
    build: build,
    seed: () => filled,
    act: (cubit) => cubit.submit(),
    skip: 1,
    expect: () => [filled.copyWith(status: SignupStatus.signedIn, user: tUser)],
  );

  blocTest<SignupCubit, SignupState>(
    'signed in but the user cannot be loaded → loginRequired',
    setUp: () {
      repository
        ..signUpResult = const Ok(false)
        ..currentUserResult = const Err(NetworkFailure());
    },
    build: build,
    seed: () => filled,
    act: (cubit) => cubit.submit(),
    skip: 1,
    expect: () => [filled.copyWith(status: SignupStatus.loginRequired)],
  );

  blocTest<SignupCubit, SignupState>(
    'a failure carries its message; the next edit clears it',
    setUp: () => repository.signUpResult = const Err(
      ServerFailure('An account with this email already exists.'),
    ),
    build: build,
    seed: () => filled,
    act: (cubit) async {
      await cubit.submit();
      cubit.nameChanged('Asha R');
    },
    skip: 1,
    expect: () => [
      filled.copyWith(
        status: SignupStatus.failure,
        errorMessage: 'An account with this email already exists.',
      ),
      filled.copyWith(name: 'Asha R'),
    ],
  );
}
