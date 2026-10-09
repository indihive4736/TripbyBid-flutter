import '../../../../core/error/guard.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Result<UserProfile>> getProfile() => guard(_remote.getProfile);

  @override
  Future<Result<UserProfile>> updateProfile({
    required String name,
    String? phone,
    String? bio,
  }) => guard(() => _remote.updateProfile(name: name, phone: phone, bio: bio));

  @override
  Future<Result<NotificationPreferences>> getPreferences() =>
      guard(_remote.getPreferences);

  @override
  Future<Result<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  ) => guard(() => _remote.updatePreferences(preferences));
}
