import 'dart:async';

import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/auth/domain/entities/user.dart';
import 'package:tripbybid/features/auth/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository]. Set the `*Result` fields to script answers;
/// calls are recorded in [calls].
class FakeAuthRepository implements AuthRepository {
  Result<User> loginResult = const Err(ServerFailure('not scripted'));
  Result<bool> signUpResult = const Ok(true);
  Result<User> verifyResult = const Err(ServerFailure('not scripted'));
  Result<void> resendResult = const Ok(null);
  Result<User?> currentUserResult = const Ok(null);
  Result<void> logoutResult = const Ok(null);

  final calls = <String>[];
  final _sessionEnded = StreamController<void>.broadcast();

  /// Simulates the session expiring while the app runs.
  void endSession() => _sessionEnded.add(null);

  @override
  Stream<void> get sessionEnded => _sessionEnded.stream;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    calls.add('login:$email');
    return loginResult;
  }

  @override
  Future<Result<bool>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    calls.add('signUp:$email:$phone');
    return signUpResult;
  }

  @override
  Future<Result<User>> verifyEmail({
    required String email,
    required String code,
  }) async {
    calls.add('verify:$email:$code');
    return verifyResult;
  }

  @override
  Future<Result<void>> resendCode(String email) async {
    calls.add('resend:$email');
    return resendResult;
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    calls.add('getCurrentUser');
    return currentUserResult;
  }

  @override
  Future<Result<void>> logout() async {
    calls.add('logout');
    return logoutResult;
  }
}
