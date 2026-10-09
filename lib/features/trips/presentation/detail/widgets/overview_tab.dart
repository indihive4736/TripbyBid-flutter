import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/trip_stage.dart';
import '../detail_labels.dart';
import '../trip_detail_cubit.dart';

const _cardBorder = Color(0x0F0D1B2A);

/// Agent, trip details, fare breakdown and the "Manage booking" grid.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.state,
    required this.onChat,
    required this.onCancel,
    required this.onEdit,
    required this.onRelease,
    required this.onHelp,
    required this.onUnavailable,
  });

  final TripDetailLoaded state;
  final VoidCallback onChat;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final VoidCallback onRelease;
  final VoidCallback onHelp;

  /// Tapped a disabled tile: explain why ([String] is the reason).
  final ValueChanged<String> onUnavailable;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    final rows = requestDetailRows(detail.request);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.hasAgent) ...[
          _AgentCard(
            name: detail.agentName ?? 'Your agent',
            rating: detail.agentRating,
            verified: detail.agentVerified,
            onChat: onChat,
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          borderColor: _cardBorder,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _DetailLine(row: rows[i], first: i == 0),
            ],
          ),
        ),
        if (detail.hasAgent) ...[
          const SizedBox(height: 12),
          _FareCard(state: state),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Manage booking', style: AppTypography.title(17)),
        ),
        _ManageGrid(tiles: _tiles(), onUnavailable: onUnavailable),
      ],
    );
  }

  List<_Manage> _tiles() {
    final detail = state.detail;
    final stage = detail.stage;
    final booked = detail.booking != null && stage.isBooked;
    final canCancel = stage != TripStage.completed && !stage.isClosed;
    return [
      _Manage(
        icon: Symbols.event_busy_rounded,
        label: booked ? 'Cancel booking' : 'Cancel request',
        sub: !canCancel
            ? 'Not available now'
            : booked
            ? 'Refund as per fare rules'
            : 'No charges yet',
        tint: AppColors.dangerTint,
        fg: AppColors.accentOnTint,
        onTap: canCancel ? onCancel : null,
      ),
      _Manage(
        icon: Symbols.edit_rounded,
        label: 'Edit request',
        sub: switch (stage) {
          TripStage.awaitingBids => 'Budget and notes',
          TripStage.bidsIn => 'Notes only — bids are in',
          _ => 'Locked once you accept a bid',
        },
        tint: AppColors.hotelTint,
        onTap: stage.isBidding ? onEdit : null,
      ),
      _Manage(
        icon: Symbols.undo_rounded,
        label: 'Release offer',
        sub: stage == TripStage.paymentDue
            ? 'Pick a different bid'
            : 'Only while payment is due',
        tint: AppColors.yellowTint,
        onTap: stage == TripStage.paymentDue ? onRelease : null,
      ),
      _Manage(
        icon: Symbols.support_agent_rounded,
        label: 'Get help',
        sub: booked ? 'Raise a support ticket' : 'We are here to help',
        tint: AppColors.successTint,
        onTap: onHelp,
      ),
    ];
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.name,
    required this.rating,
    required this.verified,
    required this.onChat,
  });

  final String name;
  final double rating;
  final bool verified;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: _cardBorder,
      child: Row(
        children: [
          InitialsAvatar(name: name, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameLine(name: name, verified: verified),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (rating > 0) ...[
                      const Icon(
                        Symbols.star_rounded,
                        fill: 1,
                        size: 13,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        rating > 0
                            ? '${rating.toStringAsFixed(1)} · Your agent'
                            : 'Your agent',
                        style: AppTypography.body(
                          12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: Symbols.chat_rounded,
            tooltip: 'Message $name',
            filled: true,
            onPressed: onChat,
          ),
        ],
      ),
    );
  }
}

/// Agent name with the green verified tick.
class _NameLine extends StatelessWidget {
  const _NameLine({required this.name, required this.verified});

  final String name;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(15, weight: FontWeight.w700),
          ),
        ),
        if (verified) ...[
          const SizedBox(width: 4),
          const Icon(
            Symbols.verified_rounded,
            fill: 1,
            size: 16,
            color: AppColors.success,
            semanticLabel: 'Verified',
          ),
        ],
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.row, required this.first});

  final DetailRow row;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: _cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(row.icon, size: 19, color: AppColors.accentDeep),
          const SizedBox(width: 12),
          Text(
            row.label,
            style: AppTypography.body(14, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              style: AppTypography.body(14, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({required this.state});

  final TripDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    final booking = detail.booking;
    final summary = state.summary;
    final List<(String, double)> lines;
    final double total;
    if (booking != null) {
      lines = [
        ('Base fare', booking.price - booking.platformFee),
        ('TripByBid fee', booking.platformFee),
      ];
      total = booking.price;
    } else if (summary != null) {
      lines = [
        ('Base fare', summary.baseFare),
        ('TripByBid fee', summary.serviceCharge),
      ];
      total = summary.total;
    } else {
      lines = const [];
      total = detail.fare ?? 0;
    }
    return AppCard(
      borderColor: _cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Fare breakdown', style: AppTypography.title(17)),
          const SizedBox(height: 10),
          for (final (label, amount) in lines)
            FareLine(label: label, amount: amount),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x240D1B2A))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    booking != null ? 'Total paid' : 'Total',
                    style: AppTypography.body(15, weight: FontWeight.w700),
                  ),
                ),
                Text(Fmt.inr(total), style: AppTypography.number(24)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Base fare ……… ₹17,699" — shared with the pay sheet.
class FareLine extends StatelessWidget {
  const FareLine({super.key, required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final free = label.contains('fee') && amount == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(14, color: AppColors.textSecondary),
            ),
          ),
          Text(
            free ? 'Free' : Fmt.inr(amount),
            style: AppTypography.number(
              14,
              tracking: 0,
              color: free ? AppColors.successOnTint : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Manage {
  const _Manage({
    required this.icon,
    required this.label,
    required this.sub,
    required this.tint,
    this.fg = AppColors.ink,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color tint;
  final Color fg;
  final VoidCallback? onTap;
}

class _ManageGrid extends StatelessWidget {
  const _ManageGrid({required this.tiles, required this.onUnavailable});

  final List<_Manage> tiles;
  final ValueChanged<String> onUnavailable;

  @override
  Widget build(BuildContext context) {
    Widget tile(_Manage m) {
      final enabled = m.onTap != null;
      return Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Semantics(
          button: true,
          enabled: enabled,
          child: AppCard(
            padding: const EdgeInsets.all(14),
            borderColor: _cardBorder,
            onTap: enabled ? m.onTap : () => onUnavailable(m.sub),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: m.icon,
                  tint: enabled ? m.tint : AppColors.muted,
                  size: 38,
                  color: enabled ? m.fg : AppColors.ink,
                ),
                const SizedBox(height: 10),
                Text(
                  m.label,
                  style: AppTypography.body(
                    14,
                    weight: FontWeight.w700,
                    color: enabled ? m.fg : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  m.sub,
                  style: AppTypography.body(11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(tiles[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tile(tiles[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
