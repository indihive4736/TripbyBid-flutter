import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/app_notification.dart';

/// Icon and tint per notification category.
extension NotificationCategoryStyle on NotificationCategory {
  IconData get icon => switch (this) {
    NotificationCategory.bids => Symbols.gavel_rounded,
    NotificationCategory.messages => Symbols.chat_rounded,
    NotificationCategory.payments => Symbols.payments_rounded,
    NotificationCategory.documents => Symbols.confirmation_number_rounded,
    NotificationCategory.updates => Symbols.notifications_rounded,
  };

  Color get tint => switch (this) {
    NotificationCategory.bids => AppColors.accentTint,
    NotificationCategory.messages => AppColors.hotelTint,
    NotificationCategory.payments => AppColors.successTint,
    NotificationCategory.documents => AppColors.trainTint,
    NotificationCategory.updates => AppColors.yellowTint,
  };
}

/// One notification row: category tile, title, message, time and, while
/// unread, bold text with an orange dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.now,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  /// Reference time for the relative stamp (tests).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;
    final time = Fmt.relative(n.createdAt, now: now);
    return Semantics(
      button: true,
      label: '${unread ? 'Unread. ' : ''}${n.title}. ${n.message}. $time',
      excludeSemantics: true,
      child: AppCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        color: unread ? AppColors.card : AppColors.paper,
        borderColor: unread ? AppColors.hairline : AppColors.divider,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              icon: n.category.icon,
              tint: n.category.tint,
              size: 44,
              fill: unread,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title.isEmpty ? 'Update' : n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            15,
                            weight: unread ? FontWeight.w800 : FontWeight.w600,
                            color: unread
                                ? AppColors.ink
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          time,
                          style: AppTypography.body(
                            11,
                            color: AppColors.textFaint,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          key: const ValueKey('unread-dot'),
                          margin: const EdgeInsets.only(top: 5),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (n.message.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      n.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        13,
                        color: unread
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                        weight: unread ? FontWeight.w500 : FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
