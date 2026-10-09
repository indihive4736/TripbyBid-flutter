import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/bid.dart';
import '../../../domain/entities/trip_stage.dart';
import '../detail_labels.dart';
import '../trip_detail_cubit.dart';

/// "Offers" with a sort toggle and the bid cards.
class BidsTab extends StatelessWidget {
  const BidsTab({
    super.key,
    required this.state,
    required this.onSelect,
    required this.onSort,
    required this.onLocked,
  });

  final TripDetailLoaded state;
  final ValueChanged<String> onSelect;
  final ValueChanged<BidSort> onSort;

  /// Tapped a bid when bids can no longer be picked ([String] says why).
  final ValueChanged<String> onLocked;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    final bids = state.sortedBids;
    final stage = detail.stage;
    if (bids.isEmpty) {
      return stage.isClosed
          ? const _Empty(
              title: 'No bids',
              message: 'No agent bid on this request.',
              pulse: false,
            )
          : const _Empty(
              title: 'Agents are reviewing',
              message:
                  'Verified agents received your request. First bids usually '
                  'land in minutes.',
              pulse: true,
            );
    }
    final picking = stage == TripStage.bidsIn;
    final cheapest = detail.comparableBids.first.id;
    final chosen = detail.chosenBid?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Offers', style: AppTypography.title(19))),
            Semantics(
              button: true,
              label: 'Sort bids',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSort(
                  state.sort == BidSort.price ? BidSort.rating : BidSort.price,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.sort == BidSort.price
                            ? 'Lowest price'
                            : 'Top rated',
                        style: AppTypography.body(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Symbols.swap_vert_rounded,
                        size: 17,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final bid in bids) ...[
          BidCard(
            bid: bid,
            selected: picking
                ? bid.id == state.selectedBidId
                : bid.id == chosen,
            locked: !picking,
            faded: !picking && bid.id != chosen,
            tag: !picking && bid.id == chosen
                ? 'ACCEPTED'
                : bid.id == cheapest
                ? 'LOWEST'
                : null,
            onTap: () {
              if (picking) {
                onSelect(bid.id);
              } else {
                onLocked(
                  chosen != null
                      ? 'You already accepted a bid'
                      : 'Bids are closed',
                );
              }
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// One agent's offer. Expands to show notes, policy and validity.
class BidCard extends StatefulWidget {
  const BidCard({
    super.key,
    required this.bid,
    required this.selected,
    required this.locked,
    required this.faded,
    required this.onTap,
    this.tag,
  });

  final Bid bid;

  /// Picked (orange) while bidding; the accepted one (green) once locked.
  final bool selected;
  final bool locked;
  final bool faded;
  final String? tag;
  final VoidCallback onTap;

  @override
  State<BidCard> createState() => _BidCardState();
}

class _BidCardState extends State<BidCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;
    final border = widget.selected
        ? (widget.locked ? AppColors.success : AppColors.accent)
        : Colors.transparent;
    final hasMore =
        _filled(bid.notes) ||
        _filled(bid.cancellationPolicy) ||
        _filled(bid.refundTerms) ||
        bid.expiresAt != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: widget.faded ? 0.55 : 1,
      child: Semantics(
        selected: widget.selected,
        button: true,
        label:
            '${bid.agentName}, ${Fmt.inr(bid.price)}'
            '${widget.tag == null ? '' : ', ${widget.tag!.toLowerCase()}'}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.selected
                    ? const Color(0xCCFF5A1F)
                    : const Color(0x660D1B2A),
                offset: Offset(0, widget.selected ? 16 : 10),
                blurRadius: widget.selected ? 30 : 24,
                spreadRadius: -20,
              ),
            ],
          ),
          child: AppCard(
            radius: 22,
            padding: const EdgeInsets.all(14),
            borderColor: border,
            borderWidth: 2,
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(name: bid.agentName, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  bid.agentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body(
                                    15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (bid.agentVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Symbols.verified_rounded,
                                  fill: 1,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              const Icon(
                                Symbols.star_rounded,
                                fill: 1,
                                size: 13,
                                color: AppColors.star,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  bidStats(bid),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Fmt.inr(bid.price),
                          style: AppTypography.number(21),
                        ),
                        if (widget.tag != null)
                          Text(
                            widget.tag!,
                            style: AppTypography.body(
                              10,
                              weight: FontWeight.w800,
                              color: widget.locked && widget.selected
                                  ? AppColors.success
                                  : AppColors.successOnTint,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (bid.inclusions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final tag in bid.inclusions) _Tag(tag)],
                  ),
                ],
                if (_filled(bid.title) || _filled(bid.timeline)) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Symbols.schedule_rounded,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            if (_filled(bid.title)) bid.title!.trim(),
                            if (_filled(bid.timeline)) bid.timeline!.trim(),
                          ].join(' · '),
                          style: AppTypography.body(
                            12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (hasMore) ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _expanded
                        ? _More(bid: bid)
                        : const SizedBox.shrink(),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentDeep,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(44, 40),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      icon: Icon(
                        _expanded
                            ? Symbols.expand_less_rounded
                            : Symbols.expand_more_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _expanded ? 'Less' : 'Details',
                        style: AppTypography.body(
                          13,
                          weight: FontWeight.w700,
                          color: AppColors.accentDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _filled(String? s) => s != null && s.trim().isNotEmpty;
}

class _More extends StatelessWidget {
  const _More({required this.bid});

  final Bid bid;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      if (_BidCardState._filled(bid.notes)) ('Notes', bid.notes!.trim()),
      if (_BidCardState._filled(bid.cancellationPolicy))
        ('Cancellation policy', bid.cancellationPolicy!.trim()),
      if (_BidCardState._filled(bid.refundTerms))
        ('Refund terms', bid.refundTerms!.trim()),
      if (bid.expiresAt != null)
        ('Offer valid until', Fmt.dateTime(bid.expiresAt!)),
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(
              items[i].$1.toUpperCase(),
              style: AppTypography.eyebrow(
                size: 10,
                color: AppColors.textFaint,
                tracking: 0.08,
              ),
            ),
            const SizedBox(height: 2),
            Text(items[i].$2, style: AppTypography.body(13, height: 1.35)),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: AppTypography.body(12, weight: FontWeight.w600),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.message,
    required this.pulse,
  });

  final String title;
  final String message;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      borderColor: const Color(0x0F0D1B2A),
      child: Column(
        children: [
          _PulsingTile(pulse: pulse),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.title(17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              14,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// The hourglass tile with the design's pulsing orange ring.
class _PulsingTile extends StatefulWidget {
  const _PulsingTile({required this.pulse});

  final bool pulse;

  @override
  State<_PulsingTile> createState() => _PulsingTileState();
}

class _PulsingTileState extends State<_PulsingTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.pulse || MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accentTint,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (widget.pulse)
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.6 * (1 - t)),
                  spreadRadius: 9 * t,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Icon(
        widget.pulse ? Symbols.hourglass_top_rounded : Symbols.gavel_rounded,
        size: 26,
        color: AppColors.accentOnTint,
      ),
    );
  }
}
