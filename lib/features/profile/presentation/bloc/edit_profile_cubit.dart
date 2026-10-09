import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';

enum EditProfileStatus { loading, loadFailure, ready, saving, saved }

final class EditProfileState extends Equatable {
  const EditProfileState({
    this.status = EditProfileStatus.loading,
    this.profile,
    this.errorMessage,
  });

  final EditProfileStatus status;

  /// The profile the form was filled from (updated after saving).
  final UserProfile? profile;

  /// Load error, or why saving failed (validation or server).
  final String? errorMessage;

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

/// Loads the profile into the form and saves edits.
class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit({
    required GetProfileUseCase getProfile,
    required UpdateProfileUseCase updateProfile,
  }) : _getProfile = getProfile,
       _updateProfile = updateProfile,
       super(const EditProfileState());

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;

  Future<void> load() async {
    emit(const EditProfileState());
    final result = await _getProfile(const NoParams());
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => EditProfileState(
        status: EditProfileStatus.ready,
        profile: value,
      ),
      Err(:final failure) => EditProfileState(
        status: EditProfileStatus.loadFailure,
        errorMessage: failure.message,
      ),
    });
  }

  Future<void> save({
    required String name,
    required String phone,
    required String bio,
  }) async {
    if (state.status != EditProfileStatus.ready) return;
    emit(
      EditProfileState(
        status: EditProfileStatus.saving,
        profile: state.profile,
      ),
    );
    final result = await _updateProfile(
      ProfileEdit(name: name, phone: phone, bio: bio),
    );
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => EditProfileState(
        status: EditProfileStatus.saved,
        profile: value,
      ),
      Err(:final failure) => EditProfileState(
        status: EditProfileStatus.ready,
        profile: state.profile,
        errorMessage: failure.message,
      ),
    });
  }
}
