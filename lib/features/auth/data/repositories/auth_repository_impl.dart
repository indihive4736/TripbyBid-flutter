import '../../../../core/error/exceptions.dart';
import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Stream<void> get sessionEnded => _remote.sessionEnded;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) => guard(() async {
    final user = await _remote.signIn(email: email, password: password);
    await _cacheQuietly(user);
    return user.toEntity();
  });

  @override
  Future<Result<bool>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => guard(
    () => _remote.signUp(
      name: name,
      email: email,
      phone: phone,
      password: password,
    ),
  );

  @override
  Future<Result<User>> verifyEmail({
    required String email,
    required String code,
  }) => guard(() async {
    final user = await _remote.verifyEmail(email: email, code: code);
    await _cacheQuietly(user);
    return user.toEntity();
  });

  @override
  Future<Result<void>> resendCode(String email) =>
      guard(() => _remote.resendCode(email));

  @override
  Future<Result<User?>> getCurrentUser() async {
    if (!_remote.hasSession) return const Ok(null);
    try {
      final user = await _remote.getProfile();
      if (user == null || user.role != 'user') {
        await _remote.signOut();
        await _clearQuietly();
        return const Ok(null);
      }
      await _cacheQuietly(user);
      return Ok(user.toEntity());
    } on UnauthorizedException {
      // The session could not be refreshed: the user is simply signed out.
      await _clearQuietly();
      return const Ok(null);
    } on NetworkException catch (e) {
      final cached = await _cachedUserOrNull();
      return cached != null ? Ok(cached) : Err(e.toFailure());
    } on AppException catch (e) {
      return Err(e.toFailure());
    }
  }

  @override
  Future<Result<void>> logout() async {
    await _remote.signOut();
    try {
      await _local.clear();
      return const Ok(null);
    } on CacheException catch (e) {
      return Err<void>(e.toFailure());
    }
  }

  Future<User?> _cachedUserOrNull() async {
    try {
      return (await _local.getCachedUser())?.toEntity();
    } on CacheException {
      return null;
    }
  }

  Future<void> _cacheQuietly(UserModel user) async {
    try {
      await _local.cacheUser(user);
    } on CacheException {
      // Only the offline start depends on it.
    }
  }

  Future<void> _clearQuietly() async {
    try {
      await _local.clear();
    } on CacheException {
      // Nothing more to do.
    }
  }
}
