import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/headings.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notifications_cubit.dart';
import 'notification_tile.dart';

/// The notification list. Reads [NotificationsCubit] from context.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key, this.now});

  /// Reference time for day groups and relative stamps (tests).
  final DateTime? now;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      unawaited(context.read<NotificationsCubit>().loadMore());
    }
  }

  void _open(AppNotification notification) {
    final target = context.read<NotificationsCubit>().open(notification);
    switch (target) {
      case TripTarget(:final requestId):
        unawaited(context.push<void>(AppRoutes.trip(requestId)));
      case ChatTarget(:final bookingId):
        unawaited(context.push<void>(AppRoutes.chat(bookingId)));
      case PaymentsTarget():
        unawaited(context.push<void>(AppRoutes.paymentHistory));
      case TripsTabTarget():
        context.go(AppRoutes.trips);
      case null:
        break;
    }
  }

  Future<void> _markAllRead() async {
    final ok = await context.read<NotificationsCubit>().markAllRead();
    if (!mounted) return;
    showAppToast(
      context,
      ok ? 'All caught up' : 'Could not mark all as read. Try again.',
      icon: ok ? Symbols.done_all_rounded : Symbols.error_rounded,
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    final state = context.watch<NotificationsCubit>().state;
    final unread = switch (state) {
      NotificationsLoaded(:final unreadCount) => unreadCount,
      _ => 0,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Symbols.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: _back,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Notifications',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(26),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: unread > 0 ? _markAllRead : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentDeep,
                      disabledForegroundColor: AppColors.textFaint,
                      minimumSize: const Size(44, 44),
                      textStyle: AppTypography.body(
                        13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            if (state is NotificationsLoaded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: SegmentedTabs<NotificationFilter>(
                  height: 40,
                  selected: state.filter,
                  onChanged: cubit.setFilter,
                  options: [
                    const SegmentOption(
                      value: NotificationFilter.all,
                      label: 'All',
                    ),
                    SegmentOption(
                      value: NotificationFilter.unread,
                      label: 'Unread',
                      badge: unread,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: switch (state) {
                NotificationsLoading() => const LoadingView(),
                NotificationsFailure(:final message) => Center(
                  child: SingleChildScrollView(
                    child: StateMessage.error(
                      message: message,
                      onRetry: cubit.load,
                    ),
                  ),
                ),
                NotificationsLoaded() => RefreshIndicator(
                  onRefresh: cubit.load,
                  child: _list(state),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(NotificationsLoaded state) {
    final visible = state.visible;
    final now = widget.now ?? DateTime.now();
    final entries = <Object>[];
    String? group;
    for (final n in visible) {
      final g = _groupOf(n.createdAt, now);
      if (g != group) entries.add(g);
      group = g;
      entries.add(n);
    }
    final showFooter = state.hasMore || state.loadingMore;

    if (visible.isEmpty && !showFooter) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          StateMessage(
            icon: Symbols.done_all_rounded,
            tint: AppColors.successTint,
            iconColor: AppColors.successOnTint,
            title: "You're all caught up",
            message: state.filter == NotificationFilter.unread
                ? 'No unread notifications.'
                : 'Updates on bids, payments and tickets will show up here.',
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      itemCount: entries.length + (showFooter ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == entries.length) return _footer(state);
        return switch (entries[i]) {
          final String label => Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 10),
            child: Eyebrow(label, color: AppColors.textTertiary),
          ),
          final AppNotification n => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotificationTile(
              key: ValueKey(n.id),
              notification: n,
              now: now,
              onTap: () => _open(n),
            ),
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _footer(NotificationsLoaded state) {
    final cubit = context.read<NotificationsCubit>();
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: AppButton(
          label: state.loadMoreFailed
              ? 'Could not load more · Retry'
              : 'Load older',
          onPressed: cubit.loadMore,
          style: AppButtonStyle.outline,
          height: 44,
          expand: false,
        ),
      ),
    );
  }

  static String _groupOf(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (!day.isBefore(today)) return 'Today';
    if (day == DateTime(now.year, now.month, now.day - 1)) return 'Yesterday';
    return 'Earlier';
  }
}
