import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/indian_phone.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase implements UseCase<UserProfile, NoParams> {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<UserProfile>> call(NoParams params) => _repository.getProfile();
}

final class ProfileEdit {
  const ProfileEdit({required this.name, this.phone, this.bio});

  final String name;
  final String? phone;
  final String? bio;
}

class UpdateProfileUseCase implements UseCase<UserProfile, ProfileEdit> {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<UserProfile>> call(ProfileEdit params) async {
    final name = params.name.trim();
    if (name.length < 2) {
      return const Err(ValidationFailure('Enter your full name.'));
    }
    if (name.length > 100) {
      return const Err(ValidationFailure('Name is too long.'));
    }
    final rawPhone = params.phone?.trim() ?? '';
    final phone = rawPhone.isEmpty ? null : IndianPhone.normalize(rawPhone);
    if (rawPhone.isNotEmpty && phone == null) {
      return const Err(
        ValidationFailure('Enter a 10-digit Indian mobile number.'),
      );
    }
    final bio = params.bio?.trim();
    if (bio != null && bio.length > 500) {
      return const Err(ValidationFailure('Bio can be up to 500 characters.'));
    }
    return _repository.updateProfile(name: name, phone: phone, bio: bio);
  }
}

class GetNotificationPreferencesUseCase
    implements UseCase<NotificationPreferences, NoParams> {
  const GetNotificationPreferencesUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<NotificationPreferences>> call(NoParams params) =>
      _repository.getPreferences();
}

class UpdateNotificationPreferencesUseCase
    implements UseCase<NotificationPreferences, NotificationPreferences> {
  const UpdateNotificationPreferencesUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<NotificationPreferences>> call(
    NotificationPreferences params,
  ) => _repository.updatePreferences(params);
}
