import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/login_usecase.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/fixtures.dart';

void main() {
  late FakeAuthRepository repository;
  late LoginUseCase login;

  setUp(() {
    repository = FakeAuthRepository();
    login = LoginUseCase(repository);
  });

  test('trims the email and delegates to the repository', () async {
    repository.loginResult = const Ok(tUser);

    final result = await login(
      const LoginParams(email: '  asha@example.com ', password: 'secret'),
    );

    expect(result, const Ok(tUser));
    expect(repository.calls, ['login:asha@example.com']);
  });

  test('rejects an invalid email without calling the repository', () async {
    final result = await login(
      const LoginParams(email: 'not-an-email', password: 'secret'),
    );

    expect(
      result,
      const Err<Never>(ValidationFailure('Enter a valid email address.')),
    );
    expect(repository.calls, isEmpty);
  });

  test('rejects an empty password without calling the repository', () async {
    final result = await login(
      const LoginParams(email: 'asha@example.com', password: ''),
    );

    expect(result, isA<Err<Object?>>());
    expect(repository.calls, isEmpty);
  });

  test('passes repository failures through', () async {
    repository.loginResult = const Err(EmailNotVerifiedFailure());

    final result = await login(
      const LoginParams(email: 'asha@example.com', password: 'secret'),
    );

    expect(result, const Err<Never>(EmailNotVerifiedFailure()));
  });
}
