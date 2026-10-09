import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/entities/password_strength.dart';
import 'package:tripbybid/features/auth/domain/usecases/sign_up_usecases.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  group('SignUpUseCase', () {
    SignUpParams params({
      String name = 'Asha Rao',
      String email = 'Asha@Example.com ',
      String phone = '098100 43210',
      String password = 'Travel#2026',
      bool terms = true,
    }) => SignUpParams(
      name: name,
      email: email,
      phone: phone,
      password: password,
      acceptedTerms: terms,
    );

    test('normalises email and phone, then signs up', () async {
      final result = await SignUpUseCase(repository)(params());

      expect(result, const Ok(true));
      expect(repository.calls, ['signUp:asha@example.com:+919810043210']);
    });

    test('rejects each invalid field before calling the backend', () async {
      final signUp = SignUpUseCase(repository);
      for (final bad in [
        params(name: 'A'),
        params(email: 'nope'),
        params(phone: '12345'),
        params(password: 'travel'),
        params(terms: false),
      ]) {
        expect(await signUp(bad), isA<Err<Object?>>());
      }
      expect(repository.calls, isEmpty);
    });
  });

  group('VerifyEmailUseCase', () {
    test('needs exactly six digits', () async {
      final verify = VerifyEmailUseCase(repository);

      expect(
        await verify(const VerifyEmailParams(email: 'a@b.co', code: '12a456')),
        const Err<Never>(ValidationFailure('Enter the 6-digit code.')),
      );
      expect(repository.calls, isEmpty);
    });

    test('verifies a valid code', () async {
      repository.verifyResult = const Ok(tUser);

      final result = await VerifyEmailUseCase(repository)(
        const VerifyEmailParams(email: 'A@B.co', code: '482193'),
      );

      expect(result, const Ok(tUser));
      expect(repository.calls, ['verify:a@b.co:482193']);
    });
  });

  group('PasswordStrength', () {
    test('scores length, capital, number and symbol', () {
      expect(PasswordStrength.of('').score, 0);
      expect(PasswordStrength.of('travelling').score, 1);
      expect(PasswordStrength.of('Travelling').score, 2);
      expect(PasswordStrength.of('Travelling1').score, 3);
      expect(PasswordStrength.of('Travelling1!').score, 4);
    });

    test('accepts 8+ characters with two of capital/number/symbol', () {
      expect(PasswordStrength.of('Travelling').isAcceptable, isFalse);
      expect(PasswordStrength.of('Travelling1').isAcceptable, isTrue);
      expect(PasswordStrength.of('Ab1!').isAcceptable, isFalse);
    });
  });
}
