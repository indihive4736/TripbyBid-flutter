import 'package:flutter/material.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/trip_request.dart';
import '../widgets/trip_style.dart';
import 'home_cubit.dart';

/// Flight / Train / Hotel tiles that open the request form pre-set.
class QuickPostGrid extends StatelessWidget {
  const QuickPostGrid({super.key, required this.onOpen});

  final ValueChanged<String> onOpen;

  static const types = [TripType.flight, TripType.train, TripType.hotel];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, type) in types.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Post a ${type.label.toLowerCase()} request',
              excludeSemantics: true,
              child: AppCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                onTap: () => onOpen(AppRoutes.newRequestOf(type.apiValue)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(icon: type.icon, tint: type.tint),
                    const SizedBox(height: 10),
                    Text(
                      type.label,
                      style: AppTypography.body(14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Post request',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Horizontally scrolling cards of requests with bids in.
class LiveBidsStrip extends StatelessWidget {
  const LiveBidsStrip({super.key, required this.items, required this.onOpen});

  final List<LiveBidSummary> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            SizedBox(
              width: 236,
              child: _LiveBidCard(
                item: item,
                onTap: () => onOpen(AppRoutes.trip(item.trip.id, tab: 'bids')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveBidCard extends StatelessWidget {
  const _LiveBidCard({required this.item, required this.onTap});

  final LiveBidSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trip = item.trip;
    final best = item.bestOffer;
    final savings = item.savingsPercent;
    final count = trip.bidsCount;
    return Semantics(
      button: true,
      label:
          '${trip.title}, $count ${count == 1 ? 'bid' : 'bids'}'
          '${best == null ? '' : ', best offer ${Fmt.inr(best)}'}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(trip.type.icon, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.shortId,
                    maxLines: 1,
                    style: AppTypography.eyebrow(
                      color: AppColors.textTertiary,
                      tracking: 0,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'bid' : 'bids'}',
                    style: AppTypography.number(
                      11,
                      color: AppColors.accentOnTint,
                      tracking: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              trip.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        best == null ? 'Offers' : 'Best offer',
                        style: AppTypography.body(
                          11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (best == null)
                        Text(
                          'Tap to compare',
                          style: AppTypography.body(
                            15,
                            weight: FontWeight.w700,
                            color: AppColors.accentDeep,
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Fmt.inr(best),
                            style: AppTypography.number(24),
                          ),
                        ),
                    ],
                  ),
                ),
                if (savings != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successTint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '−$savings%',
                      style: AppTypography.body(
                        12,
                        color: AppColors.successOnTint,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Total spent" and "Trips booked" tiles.
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({
    super.key,
    required this.totalSpent,
    required this.bookedCount,
  });

  final double totalSpent;
  final int bookedCount;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Stat(
              label: 'Total spent',
              value: Fmt.inrCompact(totalSpent),
              background: AppColors.successTint,
              labelColor: AppColors.successOnTint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              label: 'Trips booked',
              value: '$bookedCount',
              background: AppColors.card,
              labelColor: AppColors.textTertiary,
              bordered: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.background,
    required this.labelColor,
    this.bordered = false,
  });

  final String label;
  final String value;
  final Color background;
  final Color labelColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: bordered ? Border.all(color: AppColors.hairline) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.body(
                12,
                color: labelColor,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTypography.number(26)),
            ),
          ],
        ),
      ),
    );
  }
}
