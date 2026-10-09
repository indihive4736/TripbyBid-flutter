import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/trip_detail.dart';

/// E-ticket, invoice and the request summary.
class DocsTab extends StatelessWidget {
  const DocsTab({
    super.key,
    required this.detail,
    required this.onOpenTicket,
    required this.onSummary,
    required this.onLocked,
  });

  final TripDetail detail;

  /// Opens the ticket's signed URL.
  final ValueChanged<String> onOpenTicket;
  final VoidCallback onSummary;

  /// Tapped a locked document ([String] says why).
  final ValueChanged<String> onLocked;

  @override
  Widget build(BuildContext context) {
    final booking = detail.booking;
    final ticket = booking?.ticket;
    final ticketUrl = ticket?.url;
    final ticketSub = ticket != null
        ? ticketUrl == null
              ? 'Open it on the web dashboard'
              : '${ticket.fileName} · ${Fmt.date(ticket.uploadedAt)}'
        : booking == null
        ? 'Unlocks after payment'
        : 'Your agent is preparing it';
    final invoiceSub = booking == null
        ? 'Unlocks after payment'
        : 'Available on the web dashboard';
    return Column(
      children: [
        _Doc(
          icon: Symbols.confirmation_number_rounded,
          label: 'E-ticket',
          sub: ticketSub,
          tint: AppColors.flightTint,
          action: Symbols.open_in_new_rounded,
          onTap: ticketUrl == null
              ? () => onLocked(ticketSub)
              : () => onOpenTicket(ticketUrl),
          enabled: ticketUrl != null,
        ),
        const SizedBox(height: 10),
        _Doc(
          icon: Symbols.receipt_long_rounded,
          label: 'Invoice',
          sub: invoiceSub,
          tint: AppColors.successTint,
          action: Symbols.download_rounded,
          onTap: () => onLocked(invoiceSub),
          enabled: false,
        ),
        const SizedBox(height: 10),
        _Doc(
          icon: Symbols.description_rounded,
          label: 'Request summary',
          sub: 'Everything you asked for',
          tint: AppColors.muted,
          action: Symbols.visibility_rounded,
          onTap: onSummary,
          enabled: true,
        ),
      ],
    );
  }
}

class _Doc extends StatelessWidget {
  const _Doc({
    required this.icon,
    required this.label,
    required this.sub,
    required this.tint,
    required this.action,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color tint;
  final IconData action;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: AppCard(
          padding: const EdgeInsets.all(14),
          borderColor: const Color(0x0F0D1B2A),
          onTap: onTap,
          child: Row(
            children: [
              IconTile(
                icon: icon,
                tint: enabled ? tint : AppColors.muted,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body(15, weight: FontWeight.w700),
                    ),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  enabled ? action : Symbols.lock_rounded,
                  size: 19,
                  color: enabled ? AppColors.paper : AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
