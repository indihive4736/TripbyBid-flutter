import '../../../../core/error/result.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  /// Signs in a traveler. Fails with `EmailNotVerifiedFailure` when the
  /// signup code was never entered, and refuses agent/admin accounts.
  Future<Result<User>> login({required String email, required String password});

  /// Creates a traveler account. Returns `true` when a 6-digit code was
  /// emailed and must be verified, `false` when the account is already
  /// signed in.
  Future<Result<bool>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Confirms the signup code and signs the traveler in.
  Future<Result<User>> verifyEmail({
    required String email,
    required String code,
  });

  Future<Result<void>> resendCode(String email);

  /// The user of the stored session, or `Ok(null)` when signed out.
  Future<Result<User?>> getCurrentUser();

  /// Ends the session on the server (best effort) and always clears it locally.
  Future<Result<void>> logout();

  /// Emits when the session ends without the user asking (it expired or was
  /// revoked).
  Stream<void> get sessionEnded;
}
