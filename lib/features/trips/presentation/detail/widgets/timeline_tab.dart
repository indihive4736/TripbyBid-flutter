import 'package:flutter/material.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/trip_detail.dart';
import '../../../domain/entities/trip_progress.dart';
import '../detail_labels.dart';

/// What happened so far, and what comes next.
class TimelineTab extends StatelessWidget {
  const TimelineTab({super.key, required this.detail});

  final TripDetail detail;

  @override
  Widget build(BuildContext context) {
    final events = TripTimeline.of(detail);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
      borderColor: const Color(0x0F0D1B2A),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _Entry(event: events[i], last: i == events.length - 1),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.event, required this.last});

  final TimelineEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = timelineText(event);
    final done = !event.upNext;
    final cancelled =
        event.kind == TimelineKind.cancelled ||
        event.kind == TimelineKind.expired;
    final (bg, fg) = !done
        ? (AppColors.paper, AppColors.textFaint)
        : cancelled
        ? (AppColors.danger, AppColors.paper)
        : last
        ? (AppColors.accent, AppColors.ink)
        : (AppColors.ink, AppColors.paper);
    final at = event.at;
    final time = event.upNext
        ? 'UP NEXT'
        : at == null
        ? null
        : Fmt.stamp(at);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(text.icon, size: 16, color: fg),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  constraints: const BoxConstraints(minHeight: 18),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: last ? Colors.transparent : AppColors.divider,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.title,
                    style: AppTypography.body(
                      14,
                      weight: FontWeight.w700,
                      color: done ? AppColors.ink : AppColors.textFaint,
                    ),
                  ),
                  if (text.sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      text.sub,
                      style: AppTypography.body(
                        13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: AppTypography.eyebrow(
                        size: 10,
                        color: AppColors.textFaint,
                        tracking: 0.06,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
