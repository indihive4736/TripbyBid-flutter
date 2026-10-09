import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/payments/domain/usecases/payment_usecases.dart';
import 'package:tripbybid/features/profile/domain/entities/profile.dart';
import 'package:tripbybid/features/profile/domain/usecases/profile_usecases.dart';
import 'package:tripbybid/features/profile/presentation/bloc/edit_profile_cubit.dart';
import 'package:tripbybid/features/profile/presentation/bloc/notification_settings_cubit.dart';
import 'package:tripbybid/features/profile/presentation/bloc/payment_history_cubit.dart';
import 'package:tripbybid/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';

import '../../../trips/trips_fakes.dart';
import '../../profile_fakes.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakeTripsRepository trips;
  late FakePaymentsRepository payments;

  setUp(() {
    profiles = FakeProfileRepository();
    trips = FakeTripsRepository();
    payments = FakePaymentsRepository();
  });

  group('ProfileCubit', () {
    ProfileCubit build() => ProfileCubit(
      getProfile: GetProfileUseCase(profiles),
      getMyTrips: GetMyTripsUseCase(trips),
    );

    blocTest<ProfileCubit, ProfileState>(
      'loads the profile with request count and what booked trips cost',
      setUp: () => trips.myTripsResult = Ok([
        TripFixtures.request(id: 'a1', status: 'bidding', bidsCount: 2),
        TripFixtures.request(
          id: 'a2',
          status: 'confirmed',
          booking: TripFixtures.booking(price: 17999),
        ),
        TripFixtures.request(
          id: 'a3',
          status: 'completed',
          booking: TripFixtures.booking(id: 'b2', price: 6420),
        ),
        TripFixtures.request(
          id: 'a4',
          status: 'cancelled',
          booking: TripFixtures.booking(id: 'b3', price: 9999),
        ),
      ]),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProfileLoading(),
        ProfileLoaded(
          ProfileFixtures.profile,
          const ProfileStats(requests: 4, totalSpent: 17999 + 6420),
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'shows the profile without stats when trips fail',
      setUp: () => trips.myTripsResult = const Err(NetworkFailure()),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProfileLoading(),
        ProfileLoaded(ProfileFixtures.profile, null),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits an error when the profile fails',
      setUp: () => profiles.profileResult = const Err(NetworkFailure()),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProfileLoading(),
        ProfileError(const NetworkFailure().message),
      ],
    );
  });

  group('EditProfileCubit', () {
    EditProfileCubit build() => EditProfileCubit(
      getProfile: GetProfileUseCase(profiles),
      updateProfile: UpdateProfileUseCase(profiles),
    );

    blocTest<EditProfileCubit, EditProfileState>(
      'saves a normalised phone number',
      build: build,
      seed: () => EditProfileState(
        status: EditProfileStatus.ready,
        profile: ProfileFixtures.profile,
      ),
      act: (cubit) =>
          cubit.save(name: ' Asha R ', phone: '98100 43210', bio: 'Hi'),
      expect: () => [
        EditProfileState(
          status: EditProfileStatus.saving,
          profile: ProfileFixtures.profile,
        ),
        isA<EditProfileState>()
            .having((s) => s.status, 'status', EditProfileStatus.saved)
            .having((s) => s.profile?.name, 'name', 'Asha R'),
      ],
      verify: (_) => expect(
        profiles.calls,
        contains('updateProfile:Asha R:+919810043210:Hi'),
      ),
    );

    blocTest<EditProfileCubit, EditProfileState>(
      'reports validation messages from the use case',
      build: build,
      seed: () => EditProfileState(
        status: EditProfileStatus.ready,
        profile: ProfileFixtures.profile,
      ),
      act: (cubit) => cubit.save(name: 'Asha', phone: '12345', bio: ''),
      expect: () => [
        EditProfileState(
          status: EditProfileStatus.saving,
          profile: ProfileFixtures.profile,
        ),
        EditProfileState(
          status: EditProfileStatus.ready,
          profile: ProfileFixtures.profile,
          errorMessage: 'Enter a 10-digit Indian mobile number.',
        ),
      ],
    );
  });

  group('NotificationSettingsCubit', () {
    NotificationSettingsCubit build() => NotificationSettingsCubit(
      getPreferences: GetNotificationPreferencesUseCase(profiles),
      updatePreferences: UpdateNotificationPreferencesUseCase(profiles),
    );

    const loaded = NotificationSettingsState(
      status: NotificationSettingsStatus.ready,
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'saves a toggle optimistically',
      build: build,
      seed: () => loaded,
      act: (cubit) => cubit.toggle(NotificationSetting.emailPromotions, true),
      expect: () => [
        const NotificationSettingsState(
          status: NotificationSettingsStatus.ready,
          preferences: NotificationPreferences(emailPromotions: true),
        ),
      ],
      verify: (_) => expect(
        profiles.lastSavedPreferences,
        const NotificationPreferences(emailPromotions: true),
      ),
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'reverts the toggle when saving fails',
      setUp: () => profiles.updatePreferencesResult = const Err(
        ServerFailure('Could not save preferences.'),
      ),
      build: build,
      seed: () => loaded,
      act: (cubit) =>
          cubit.toggle(NotificationSetting.pushMessageAlerts, false),
      expect: () => [
        const NotificationSettingsState(
          status: NotificationSettingsStatus.ready,
          preferences: NotificationPreferences(pushMessageAlerts: false),
        ),
        const NotificationSettingsState(
          status: NotificationSettingsStatus.ready,
          saveError: 'Could not save preferences.',
          saveErrorCount: 1,
        ),
      ],
    );
  });

  group('PaymentHistoryCubit', () {
    PaymentHistoryCubit build() =>
        PaymentHistoryCubit(getHistory: GetPaymentHistoryUseCase(payments));

    final payment = ProfileFixtures.payment();

    blocTest<PaymentHistoryCubit, PaymentHistoryState>(
      'loads the history',
      setUp: () => payments.historyResult = Ok([payment]),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const PaymentHistoryLoading(),
        PaymentHistoryLoaded([payment]),
      ],
    );

    blocTest<PaymentHistoryCubit, PaymentHistoryState>(
      'emits an error when loading fails',
      setUp: () => payments.historyResult = const Err(NetworkFailure()),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const PaymentHistoryLoading(),
        PaymentHistoryError(const NetworkFailure().message),
      ],
    );
  });
}
