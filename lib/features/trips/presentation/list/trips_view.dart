import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/trip_request.dart';
import '../widgets/trip_style.dart';
import 'trip_list_card.dart';
import 'trips_list_cubit.dart';

/// 02 My trips. Reads [TripsListCubit] from context.
class TripsView extends StatelessWidget {
  const TripsView({super.key});

  /// Pushes [route] and refreshes the list once the user comes back.
  static Future<void> _open(BuildContext context, String route) async {
    final cubit = context.read<TripsListCubit>();
    await context.push<void>(route);
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsListCubit>();
    final state = context.watch<TripsListCubit>().state;
    final bottom = math.max(
      AppBottomNav.reservedHeight,
      MediaQuery.paddingOf(context).bottom,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: cubit.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    filtered: state is TripsListLoaded && state.type != null,
                    onFilter: state is TripsListLoaded
                        ? () => _showFilter(context, state)
                        : null,
                  ),
                ),
              ),
              ...switch (state) {
                TripsListLoading() => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingView(),
                  ),
                ],
                TripsListFailure(:final message) => [
                  SliverToBoxAdapter(
                    child: StateMessage.error(
                      message: message,
                      onRetry: cubit.load,
                    ),
                  ),
                ],
                TripsListLoaded() => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: SegmentedTabs<TripSegment>(
                        height: 40,
                        selected: state.segment,
                        onChanged: cubit.selectSegment,
                        options: [
                          for (final s in TripSegment.values)
                            SegmentOption(
                              value: s,
                              label: _segmentLabel(s),
                              count: state.count(s),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (state.visible.isEmpty)
                    SliverToBoxAdapter(child: _empty(context, state))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: state.visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final trip = state.visible[i];
                          return TripListCard(
                            key: ValueKey(trip.id),
                            trip: trip,
                            onTap: () =>
                                _open(context, AppRoutes.trip(trip.id)),
                          );
                        },
                      ),
                    ),
                ],
              },
              SliverToBoxAdapter(child: SizedBox(height: bottom + 16)),
            ],
          ),
        ),
      ),
    );
  }

  static String _segmentLabel(TripSegment s) => switch (s) {
    TripSegment.active => 'Active',
    TripSegment.past => 'Past',
    TripSegment.all => 'All',
  };

  Widget _empty(BuildContext context, TripsListLoaded state) {
    final type = state.type;
    if (type != null) {
      return StateMessage(
        icon: type.icon,
        tint: type.tint,
        iconColor: AppColors.ink,
        title: 'No ${type.label.toLowerCase()} trips here',
        message: 'Clear the filter to see your other trips.',
        actionLabel: 'Show all types',
        onAction: () => context.read<TripsListCubit>().filterType(null),
      );
    }
    void post() => _open(context, AppRoutes.newRequest);
    return switch (state.segment) {
      TripSegment.active => StateMessage(
        icon: Symbols.luggage_rounded,
        title: 'No active trips — post your first request',
        message: 'Tell us where you are going; verified agents bid for it.',
        actionLabel: 'Post a request',
        onAction: post,
      ),
      TripSegment.past => const StateMessage(
        icon: Symbols.history_rounded,
        title: 'No past trips yet',
        message: 'Completed, cancelled and expired trips show up here.',
      ),
      TripSegment.all => StateMessage(
        icon: Symbols.luggage_rounded,
        title: 'No trips yet',
        message: 'Post one request and let agents compete for it.',
        actionLabel: 'Post a request',
        onAction: post,
      ),
    };
  }

  Future<void> _showFilter(BuildContext context, TripsListLoaded state) async {
    final cubit = context.read<TripsListCubit>();
    final picked = await showModalBottomSheet<_TypeChoice>(
      context: context,
      useRootNavigator: true,
      builder: (_) =>
          _TypeFilterSheet(types: state.filterTypes, selected: state.type),
    );
    if (picked != null && !cubit.isClosed) cubit.filterType(picked.type);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.filtered, required this.onFilter});

  final bool filtered;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'My trips',
              style: AppTypography.display(
                34,
              ).copyWith(letterSpacing: -0.045 * 34),
            ),
          ),
        ),
        AppIconButton(
          icon: Symbols.tune_rounded,
          size: 46,
          badge: filtered,
          tooltip: filtered ? 'Filter by type (on)' : 'Filter by type',
          onPressed: onFilter,
        ),
      ],
    );
  }
}

/// Wraps the sheet's answer so "all types" (null) differs from dismissal.
class _TypeChoice {
  const _TypeChoice(this.type);

  final TripType? type;
}

class _TypeFilterSheet extends StatelessWidget {
  const _TypeFilterSheet({required this.types, required this.selected});

  final List<TripType> types;
  final TripType? selected;

  @override
  Widget build(BuildContext context) {
    Widget option({
      required TripType? type,
      required String label,
      required IconData icon,
      required Color tint,
    }) {
      final on = type == selected;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Semantics(
          selected: on,
          child: AppCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderColor: on ? AppColors.ink : AppColors.hairline,
            borderWidth: on ? 1.5 : 1,
            onTap: () => Navigator.of(context).pop(_TypeChoice(type)),
            child: Row(
              children: [
                IconTile(icon: icon, tint: tint),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body(15, weight: FontWeight.w700),
                  ),
                ),
                if (on)
                  const Icon(
                    Symbols.check_circle_rounded,
                    fill: 1,
                    color: AppColors.accent,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Show trips', style: AppTypography.title(20)),
            const SizedBox(height: 14),
            option(
              type: null,
              label: 'All types',
              icon: Symbols.apps_rounded,
              tint: AppColors.muted,
            ),
            for (final t in types)
              option(type: t, label: t.label, icon: t.icon, tint: t.tint),
          ],
        ),
      ),
    );
  }
}
