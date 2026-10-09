import '../../../../core/error/exceptions.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.login(email: email, password: password);
      await _local.saveSession(response.tokens, response.user);
      return Ok(response.user.toEntity());
    } on AppException catch (e) {
      return Err(e.toFailure());
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      if (!await _local.hasSession()) return const Ok(null);
      final user = await _remote.getCurrentUser();
      if (user == null) {
        await _local.clearSession();
        return const Ok(null);
      }
      await _local.cacheUser(user);
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
    try {
      await _remote.logout();
    } on AppException {
      // Best effort: the local session is cleared regardless.
    }
    try {
      await _local.clearSession();
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

  Future<void> _clearQuietly() async {
    try {
      await _local.clearSession();
    } on CacheException {
      // Nothing more to do; the tokens are already unusable.
    }
  }
}
