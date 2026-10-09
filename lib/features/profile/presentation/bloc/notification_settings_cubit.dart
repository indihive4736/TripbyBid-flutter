import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';

/// One switch on the notification settings screen.
enum NotificationSetting {
  pushBookingAlerts,
  pushMessageAlerts,
  pushTravelReminders,
  emailBookingUpdates,
  emailNewBids,
  emailMessages,
  emailPromotions;

  bool valueIn(NotificationPreferences p) => switch (this) {
    pushBookingAlerts => p.pushBookingAlerts,
    pushMessageAlerts => p.pushMessageAlerts,
    pushTravelReminders => p.pushTravelReminders,
    emailBookingUpdates => p.emailBookingUpdates,
    emailNewBids => p.emailNewBids,
    emailMessages => p.emailMessages,
    emailPromotions => p.emailPromotions,
  };

  NotificationPreferences apply(NotificationPreferences p, bool on) =>
      switch (this) {
        pushBookingAlerts => p.copyWith(pushBookingAlerts: on),
        pushMessageAlerts => p.copyWith(pushMessageAlerts: on),
        pushTravelReminders => p.copyWith(pushTravelReminders: on),
        emailBookingUpdates => p.copyWith(emailBookingUpdates: on),
        emailNewBids => p.copyWith(emailNewBids: on),
        emailMessages => p.copyWith(emailMessages: on),
        emailPromotions => p.copyWith(emailPromotions: on),
      };
}

enum NotificationSettingsStatus { loading, failure, ready }

final class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.loading,
    this.preferences = const NotificationPreferences(),
    this.errorMessage,
    this.saveError,
    this.saveErrorCount = 0,
  });

  final NotificationSettingsStatus status;
  final NotificationPreferences preferences;

  /// Why loading failed.
  final String? errorMessage;

  /// Why the last change could not be saved; [saveErrorCount] increases
  /// with each failure so the screen shows one toast per failure.
  final String? saveError;
  final int saveErrorCount;

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationPreferences? preferences,
    String? saveError,
    int? saveErrorCount,
  }) => NotificationSettingsState(
    status: status ?? this.status,
    preferences: preferences ?? this.preferences,
    errorMessage: errorMessage,
    saveError: saveError ?? this.saveError,
    saveErrorCount: saveErrorCount ?? this.saveErrorCount,
  );

  @override
  List<Object?> get props => [
    status,
    preferences,
    errorMessage,
    saveError,
    saveErrorCount,
  ];
}

/// Email and push preferences, saved one switch at a time.
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required GetNotificationPreferencesUseCase getPreferences,
    required UpdateNotificationPreferencesUseCase updatePreferences,
  }) : _getPreferences = getPreferences,
       _updatePreferences = updatePreferences,
       super(const NotificationSettingsState());

  final GetNotificationPreferencesUseCase _getPreferences;
  final UpdateNotificationPreferencesUseCase _updatePreferences;

  Future<void> load() async {
    emit(const NotificationSettingsState());
    final result = await _getPreferences(const NoParams());
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => NotificationSettingsState(
        status: NotificationSettingsStatus.ready,
        preferences: value,
      ),
      Err(:final failure) => NotificationSettingsState(
        status: NotificationSettingsStatus.failure,
        errorMessage: failure.message,
      ),
    });
  }

  /// Flips [setting] at once and saves; reverts it if saving fails.
  Future<void> toggle(NotificationSetting setting, bool on) async {
    if (state.status != NotificationSettingsStatus.ready) return;
    final updated = setting.apply(state.preferences, on);
    emit(state.copyWith(preferences: updated));
    final result = await _updatePreferences(updated);
    if (isClosed) return;
    if (result case Err(:final failure)) {
      // Revert only this switch: others may have changed meanwhile.
      emit(
        state.copyWith(
          preferences: setting.apply(state.preferences, !on),
          saveError: failure.message,
          saveErrorCount: state.saveErrorCount + 1,
        ),
      );
    }
  }
}
