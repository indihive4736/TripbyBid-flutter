import '../../../../core/error/result.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  /// Signs in and stores the session.
  Future<Result<User>> login({required String email, required String password});

  /// The user of the stored session, or `Ok(null)` when signed out.
  Future<Result<User?>> getCurrentUser();

  /// Ends the session on the server (best effort) and always clears it locally.
  Future<Result<void>> logout();
}
