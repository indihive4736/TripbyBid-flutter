import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/profile_cubit.dart';
import '../widgets/profile_widgets.dart';

/// The Profile tab.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.onLogout});

  final User user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileCubit>()..load(),
      child: ProfileView(user: user, onLogout: onLogout),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.user, required this.onLogout});

  /// The signed-in account, shown until the full profile loads.
  final User user;
  final VoidCallback onLogout;

  Future<void> _open(BuildContext context, String route) async {
    final cubit = context.read<ProfileCubit>();
    await context.push(route);
    if (route == AppRoutes.editProfile) await cubit.refresh();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _LogoutSheet(),
    );
    if (confirmed ?? false) onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final profile = switch (state) {
              ProfileLoaded(:final profile) => profile,
              _ => null,
            };
            final name = profile?.name ?? user.name;
            final email = profile?.email ?? user.email;
            final since = profile?.createdAt?.year;
            return RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  AppBottomNav.reservedHeight + 24,
                ),
                children: [
                  Center(
                    child: _Avatar(
                      name: name,
                      onEdit: () => _open(context, AppRoutes.editProfile),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      26,
                      weight: FontWeight.w800,
                    ).copyWith(letterSpacing: -0.035 * 26),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    since == null ? email : '$email · Member since $since',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  switch (state) {
                    ProfileError(:final message) => AppCard(
                      child: StateMessage.error(
                        message: message,
                        onRetry: cubit.load,
                      ),
                    ),
                    ProfileLoading() => const _StatsPanel(
                      completed: null,
                      stats: null,
                    ),
                    ProfileLoaded(:final profile, :final stats) => _StatsPanel(
                      completed: profile.completedTrips,
                      stats: stats,
                    ),
                  },
                  MenuGroup(
                    label: 'Account',
                    children: [
                      MenuRow(
                        icon: Symbols.badge_rounded,
                        tint: AppColors.flightTint,
                        label: 'Personal details',
                        onTap: () => _open(context, AppRoutes.editProfile),
                      ),
                      MenuRow(
                        icon: Symbols.receipt_long_rounded,
                        tint: AppColors.successTint,
                        label: 'Payments & receipts',
                        onTap: () => _open(context, AppRoutes.paymentHistory),
                      ),
                    ],
                  ),
                  MenuGroup(
                    label: 'Preferences',
                    children: [
                      MenuRow(
                        icon: Symbols.notifications_rounded,
                        tint: AppColors.yellowTint,
                        label: 'Notifications',
                        onTap: () =>
                            _open(context, AppRoutes.notificationSettings),
                      ),
                      MenuRow(
                        icon: Symbols.support_agent_rounded,
                        tint: AppColors.trainTint,
                        label: 'Help & support',
                        onTap: () => _open(context, AppRoutes.help),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _LogoutButton(onPressed: () => _confirmLogout(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.onEdit});

  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Wider than the 92 px avatar so the whole 44 px badge target is inside
    // the stack (and hit-testable).
    return SizedBox(
      width: 114,
      height: 102,
      child: Stack(
        children: [
          Positioned(
            left: 11,
            top: 0,
            child: Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment(-0.5, -1),
                  end: Alignment(0.5, 1),
                  colors: [AppColors.accentSoft, AppColors.accent],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCCFF5A1F),
                    offset: Offset(0, 20),
                    blurRadius: 34,
                    spreadRadius: -16,
                  ),
                ],
              ),
              child: Text(
                InitialsAvatar.initialsOf(name),
                style: AppTypography.body(32, weight: FontWeight.w800),
              ),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 0,
            child: Tooltip(
              message: 'Edit profile',
              child: Semantics(
                button: true,
                label: 'Edit profile',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    // Grows the tap target to 44 px around the 32 px badge.
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.paper, width: 3),
                      ),
                      child: const Icon(
                        Symbols.edit_rounded,
                        size: 15,
                        color: AppColors.onInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navy panel with three figures: completed trips, requests, total spent.
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.completed, required this.stats});

  final int? completed;
  final ProfileStats? stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return InkPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(26)),
      glow: const Alignment(1.1, 1.6),
      glowSize: 220,
      glowOpacity: 0.4,
      rings: false,
      shadow: false,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Stat(value: completed?.toString() ?? '—', label: 'Trips'),
            ),
            const _Rule(),
            Expanded(
              child: _Stat(
                value: s?.requests.toString() ?? '—',
                label: 'Requests',
              ),
            ),
            const _Rule(),
            Expanded(
              child: _Stat(
                value: s == null ? '—' : Fmt.inrCompact(s.totalSpent),
                label: 'Total spent',
                color: AppColors.mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    margin: const EdgeInsets.only(right: 14),
    color: const Color(0x1FFFFFFF),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.color = AppColors.onInk,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppTypography.number(24, color: color)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.body(12, color: AppColors.onInkTertiary),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: Color(0x4DC2410C), width: 1.5),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Symbols.logout_rounded,
                  size: 19,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log out',
                  style: AppTypography.body(
                    15,
                    color: AppColors.danger,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log out?', style: AppTypography.title(22)),
            const SizedBox(height: 6),
            Text(
              'You will need to sign in again to see your trips and chats.',
              style: AppTypography.body(
                15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Log out',
              style: AppButtonStyle.danger,
              leadingIcon: Symbols.logout_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Cancel',
              style: AppButtonStyle.outline,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
