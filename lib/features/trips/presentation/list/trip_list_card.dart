import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/headings.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../../domain/entities/trip_request.dart';
import '../widgets/trip_style.dart';

/// One request in "My trips": type, route, dates, status, budget and the
/// paid fare or bid count.
class TripListCard extends StatelessWidget {
  const TripListCard({super.key, required this.trip, required this.onTap});

  final TripRequest trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stage = trip.stage;
    final (pillBg, pillFg) = stage.pillColors;
    final status = stage.pillLabel(bidsCount: trip.bidsCount);
    final booking = trip.booking;
    final (secondLabel, secondValue) = booking != null
        ? ('Paid', Fmt.inr(booking.price))
        : (
            'Bids',
            stage.isBidding && trip.bidsCount > 0 ? '${trip.bidsCount}' : '—',
          );
    final faint = secondValue == '—';

    return Semantics(
      button: true,
      label:
          '${trip.type.label} ${trip.title}, ${trip.whenLine}, $status, '
          'budget ${Fmt.inr(trip.budget)}, '
          '$secondLabel ${faint ? 'none' : secondValue}',
      excludeSemantics: true,
      child: AppCard(
        radius: 26,
        shadow: true,
        onTap: onTap,
        child: Column(
          children: [
            Row(
              children: [
                IconTile(icon: trip.type.icon, tint: trip.type.tint, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(16, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        trip.whenLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatusPill(
                      label: status,
                      background: pillBg,
                      foreground: pillFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const DashedLine(thickness: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _Figure(label: 'Budget', value: Fmt.inr(trip.budget)),
                      _Figure(
                        label: secondLabel,
                        value: secondValue,
                        faint: faint,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Symbols.arrow_forward_rounded,
                    size: 19,
                    color: AppColors.onInk,
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

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.faint = false});

  final String label;
  final String value;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body(11, color: AppColors.textTertiary),
        ),
        Text(
          value,
          style: AppTypography.number(
            15,
            color: faint ? AppColors.textFaint : AppColors.ink,
            tracking: -0.02,
          ),
        ),
      ],
    );
  }
}
