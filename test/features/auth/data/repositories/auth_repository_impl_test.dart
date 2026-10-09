import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tripbybid/core/error/exceptions.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/data/models/login_response_model.dart';
import 'package:tripbybid/features/auth/data/repositories/auth_repository_impl.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(remote: remote, local: local);
  });

  group('login', () {
    test('saves the session and returns the user', () async {
      when(remote.login(email: 'a@b.co', password: 'pw')).thenAnswer(
        (_) async => LoginResponseModel(user: tUserModel, tokens: tTokens),
      );

      final result = await repository.login(email: 'a@b.co', password: 'pw');

      expect(result, const Ok(tUser));
      verify(local.saveSession(tTokens, tUserModel));
    });

    test('maps a 401 to UnauthorizedFailure with the server message', () async {
      when(
        remote.login(email: anyNamed('email'), password: anyNamed('password')),
      ).thenThrow(const UnauthorizedException('Invalid credentials'));

      final result = await repository.login(email: 'a@b.co', password: 'x');

      expect(
        result,
        const Err<Never>(UnauthorizedFailure('Invalid credentials')),
      );
      verifyNever(local.saveSession(any, any));
    });
  });

  group('getCurrentUser', () {
    test(
      'is signed out without asking the server when there is no session',
      () async {
        when(local.hasSession()).thenAnswer((_) async => false);

        expect(await repository.getCurrentUser(), const Ok<Object?>(null));
        verifyZeroInteractions(remote);
      },
    );

    test('returns and caches the server profile', () async {
      when(local.hasSession()).thenAnswer((_) async => true);
      when(remote.getCurrentUser()).thenAnswer((_) async => tUserModel);

      expect(await repository.getCurrentUser(), const Ok(tUser));
      verify(local.cacheUser(tUserModel));
    });

    test('a dead session clears local state and reports signed out', () async {
      when(local.hasSession()).thenAnswer((_) async => true);
      when(remote.getCurrentUser()).thenThrow(const UnauthorizedException());

      expect(await repository.getCurrentUser(), const Ok<Object?>(null));
      verify(local.clearSession());
    });

    test('offline falls back to the cached profile', () async {
      when(local.hasSession()).thenAnswer((_) async => true);
      when(remote.getCurrentUser()).thenThrow(const NetworkException());
      when(local.getCachedUser()).thenAnswer((_) async => tUserModel);

      expect(await repository.getCurrentUser(), const Ok(tUser));
    });

    test('offline with nothing cached is a NetworkFailure', () async {
      when(local.hasSession()).thenAnswer((_) async => true);
      when(remote.getCurrentUser()).thenThrow(const NetworkException());
      when(local.getCachedUser()).thenAnswer((_) async => null);

      expect(await repository.getCurrentUser(), isA<Err<Object?>>());
    });
  });

  group('logout', () {
    test('clears the local session even when the server call fails', () async {
      when(remote.logout()).thenThrow(const NetworkException());

      expect(await repository.logout(), const Ok<void>(null));
      verify(local.clearSession());
    });
  });
}
