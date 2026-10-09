import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../trips/domain/entities/trip_request.dart';
import '../../../trips/domain/usecases/trip_queries.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';

/// Figures for the stats panel; null when trips could not be loaded.
final class ProfileStats extends Equatable {
  const ProfileStats({required this.requests, required this.totalSpent});

  /// Every request the traveler has posted.
  final int requests;

  /// What the traveler paid for booked (not cancelled) trips, INR.
  final double totalSpent;

  static ProfileStats of(List<TripRequest> trips) => ProfileStats(
    requests: trips.length,
    totalSpent: trips
        .where((t) => t.booking != null && t.stage.isBooked)
        .fold(0, (sum, t) => sum + t.booking!.price),
  );

  @override
  List<Object?> get props => [requests, totalSpent];
}

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile, this.stats);

  final UserProfile profile;
  final ProfileStats? stats;

  @override
  List<Object?> get props => [profile, stats];
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The Profile tab: the traveler's profile and trip figures.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetProfileUseCase getProfile,
    required GetMyTripsUseCase getMyTrips,
  }) : _getProfile = getProfile,
       _getMyTrips = getMyTrips,
       super(const ProfileLoading());

  final GetProfileUseCase _getProfile;
  final GetMyTripsUseCase _getMyTrips;

  Future<void> load() async {
    emit(const ProfileLoading());
    await refresh();
  }

  /// Reloads in place: a failed refresh keeps what is shown.
  Future<void> refresh() async {
    final tripsFuture = _getMyTrips(const NoParams());
    final profile = await _getProfile(const NoParams());
    final trips = await tripsFuture;
    if (isClosed) return;
    switch (profile) {
      case Ok(:final value):
        final stats = switch (trips) {
          Ok(value: final list) => ProfileStats.of(list),
          Err() => switch (state) {
            ProfileLoaded(:final stats) => stats,
            _ => null,
          },
        };
        emit(ProfileLoaded(value, stats));
      case Err(:final failure):
        if (state is! ProfileLoaded) emit(ProfileError(failure.message));
    }
  }
}
