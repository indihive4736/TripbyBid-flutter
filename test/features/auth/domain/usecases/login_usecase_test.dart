import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/usecases/login_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LoginUseCase login;

  setUpAll(provideResultDummies);

  setUp(() {
    repository = MockAuthRepository();
    login = LoginUseCase(repository);
  });

  test('trims the email and delegates to the repository', () async {
    when(
      repository.login(email: 'asha@example.com', password: 'secret'),
    ).thenAnswer((_) async => const Ok(tUser));

    final result = await login(
      const LoginParams(email: '  asha@example.com ', password: 'secret'),
    );

    expect(result, const Ok(tUser));
  });

  test('rejects an invalid email without calling the repository', () async {
    final result = await login(
      const LoginParams(email: 'not-an-email', password: 'secret'),
    );

    expect(
      result,
      const Err<Never>(ValidationFailure('Enter a valid email address.')),
    );
    verifyZeroInteractions(repository);
  });

  test('rejects an empty password without calling the repository', () async {
    final result = await login(
      const LoginParams(email: 'asha@example.com', password: ''),
    );

    expect(result, isA<Err<Object?>>());
    verifyZeroInteractions(repository);
  });

  test('passes repository failures through', () async {
    when(
      repository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    ).thenAnswer(
      (_) async => const Err(UnauthorizedFailure('Invalid credentials')),
    );

    final result = await login(
      const LoginParams(email: 'asha@example.com', password: 'wrong'),
    );

    expect(
      result,
      const Err<Never>(UnauthorizedFailure('Invalid credentials')),
    );
  });
}
