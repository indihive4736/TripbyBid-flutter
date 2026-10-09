import '../../../../core/error/result.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> getProfile();
  Future<Result<UserProfile>> updateProfile({
    required String name,
    String? phone,
    String? bio,
  });
  Future<Result<NotificationPreferences>> getPreferences();
  Future<Result<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  );
}
