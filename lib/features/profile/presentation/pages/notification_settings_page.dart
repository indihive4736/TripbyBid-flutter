import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/notification_settings_cubit.dart';
import '../widgets/profile_widgets.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationSettingsCubit>()..load(),
      child: const NotificationSettingsView(),
    );
  }
}

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  static const _push = [
    (
      NotificationSetting.pushBookingAlerts,
      'Booking alerts',
      Symbols.confirmation_number_rounded,
      AppColors.flightTint,
    ),
    (
      NotificationSetting.pushMessageAlerts,
      'Message alerts',
      Symbols.chat_rounded,
      AppColors.hotelTint,
    ),
    (
      NotificationSetting.pushTravelReminders,
      'Travel reminders',
      Symbols.alarm_rounded,
      AppColors.yellowTint,
    ),
  ];

  static const _email = [
    (
      NotificationSetting.emailBookingUpdates,
      'Booking updates',
      Symbols.luggage_rounded,
      AppColors.flightTint,
    ),
    (
      NotificationSetting.emailNewBids,
      'New bids',
      Symbols.gavel_rounded,
      AppColors.accentTint,
    ),
    (
      NotificationSetting.emailMessages,
      'Messages',
      Symbols.mail_rounded,
      AppColors.hotelTint,
    ),
    (
      NotificationSetting.emailPromotions,
      'Promotions',
      Symbols.sell_rounded,
      AppColors.trainTint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationSettingsCubit>();
    return BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
      listenWhen: (a, b) => a.saveErrorCount != b.saveErrorCount,
      listener: (context, state) => showAppToast(
        context,
        state.saveError ?? 'Could not save that change.',
        icon: Symbols.error_rounded,
      ),
      builder: (context, state) {
        const header = SubpageHeader(
          lead: 'Your ',
          accent: 'notifications.',
          subtitle: 'Choose what we tell you about, and where.',
        );
        Widget group(
          String label,
          List<(NotificationSetting, String, IconData, Color)> rows,
        ) => MenuGroup(
          label: label,
          children: [
            for (final (setting, title, icon, tint) in rows)
              () {
                final on = setting.valueIn(state.preferences);
                return MenuRow(
                  icon: icon,
                  tint: tint,
                  label: title,
                  semanticsToggled: on,
                  onTap: () => cubit.toggle(setting, !on),
                  trailing: DesignToggle(value: on),
                );
              }(),
          ],
        );

        return Scaffold(
          body: SafeArea(
            child: switch (state.status) {
              NotificationSettingsStatus.loading => const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: header,
                  ),
                  Expanded(child: LoadingView()),
                ],
              ),
              NotificationSettingsStatus.failure => ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                children: [
                  header,
                  StateMessage.error(
                    message: state.errorMessage ?? 'Could not load settings.',
                    onRetry: cubit.load,
                  ),
                ],
              ),
              NotificationSettingsStatus.ready => ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                children: [
                  header,
                  const SizedBox(height: 4),
                  group('Push', _push),
                  group('Email', _email),
                ],
              ),
            },
          ),
        );
      },
    );
  }
}
