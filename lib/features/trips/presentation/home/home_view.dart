import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/headings.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/user.dart';
import 'home_cubit.dart';
import 'home_hero_card.dart';
import 'home_sections.dart';

/// The home dashboard. Reads [HomeCubit] from context.
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.user});

  final User user;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Refresh when the app comes back to the foreground: bids and statuses
  // have no realtime channel.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<HomeCubit>().load(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Pushes [route] and refreshes once the user comes back.
  Future<void> _open(String route) async {
    final cubit = context.read<HomeCubit>();
    await context.push<void>(route);
    if (!cubit.isClosed) await cubit.load();
  }

  String get _firstName {
    final name = widget.user.name.trim();
    if (name.isNotEmpty) return name.split(RegExp(r'\s+')).first;
    return widget.user.email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeCubit>().state;
    final unread = switch (state) {
      HomeLoaded(:final unreadCount) => unreadCount,
      _ => 0,
    };
    // Inside the tab shell (extendBody) the padding already includes the
    // floating nav; standalone it does not.
    final bottom = math.max(
      AppBottomNav.reservedHeight,
      MediaQuery.paddingOf(context).bottom,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: context.read<HomeCubit>().load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 10, 0, bottom + 16),
            children: [
              _pad(
                _Header(
                  firstName: _firstName,
                  fullName: widget.user.name.trim().isEmpty
                      ? widget.user.email
                      : widget.user.name,
                  unread: unread,
                  onNotifications: () => _open(AppRoutes.notifications),
                ),
              ),
              const SizedBox(height: 20),
              ...switch (state) {
                HomeLoading() => [
                  const SizedBox(height: 120, child: LoadingView()),
                ],
                HomeFailure(:final message) => [
                  StateMessage.error(
                    message: message,
                    onRetry: context.read<HomeCubit>().load,
                  ),
                ],
                HomeLoaded() => _loaded(state),
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _loaded(HomeLoaded state) => [
    _pad(
      HomeHeroCard(
        highlight: state.highlight,
        today: DateTime.now(),
        onOpen: _open,
      ),
    ),
    const SizedBox(height: 16),
    _pad(QuickPostGrid(onOpen: _open)),
    if (state.liveBids.isNotEmpty) ...[
      const SizedBox(height: 24),
      _pad(
        SectionHeader(
          title: 'Live bids',
          action: 'See all',
          onAction: () => context.go(AppRoutes.trips),
        ),
      ),
      const SizedBox(height: 12),
      LiveBidsStrip(items: state.liveBids, onOpen: _open),
    ],
    const SizedBox(height: 14),
    _pad(
      HomeStatsRow(
        totalSpent: state.totalSpent,
        bookedCount: state.bookedCount,
      ),
    ),
  ];

  static Widget _pad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: child,
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.firstName,
    required this.fullName,
    required this.unread,
    required this.onNotifications,
  });

  final String firstName;
  final String fullName;
  final int unread;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Fmt.greeting(DateTime.now()),
                style: AppTypography.body(14, color: AppColors.textTertiary),
              ),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(
                  26,
                ).copyWith(letterSpacing: -0.035 * 26, height: 1.1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AppIconButton(
          icon: Symbols.notifications_rounded,
          size: 46,
          badge: unread > 0,
          tooltip: unread > 0
              ? 'Notifications, $unread unread'
              : 'Notifications',
          onPressed: onNotifications,
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Profile',
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () => context.go(AppRoutes.profile),
              borderRadius: BorderRadius.circular(16),
              child: InitialsAvatar(
                name: fullName,
                size: 46,
                gradient: const LinearGradient(
                  begin: Alignment(-0.5, -1),
                  end: Alignment(0.5, 1),
                  colors: [AppColors.accentSoft, AppColors.accent],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
