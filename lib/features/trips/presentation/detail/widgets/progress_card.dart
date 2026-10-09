import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/format/formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/trip_progress.dart';
import '../../../domain/entities/trip_stage.dart';

/// Posted · Bids · Accepted · Paid · Ticketed, plus the fare-hold countdown
/// while payment is due.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.stage,
    this.holdUntil,
    this.onHoldExpired,
  });

  final TripStage stage;

  /// Payment deadline of the accepted offer (shown while payment is due).
  final DateTime? holdUntil;
  final VoidCallback? onHoldExpired;

  static const _steps = [
    (TripStep.posted, 'Posted', Symbols.edit_note_rounded),
    (TripStep.bids, 'Bids', Symbols.gavel_rounded),
    (TripStep.accepted, 'Accepted', Symbols.handshake_rounded),
    (TripStep.paid, 'Paid', Symbols.payments_rounded),
    (TripStep.ticketed, 'Ticketed', Symbols.confirmation_number_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final progress = TripProgress.of(stage);
    final statuses = [for (final s in _steps) progress.statusOf(s.$1)];
    Color lineOf(int i) =>
        statuses[i] == TripStepStatus.done ||
            statuses[i] == TripStepStatus.current
        ? AppColors.ink
        : AppColors.divider;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      borderColor: const Color(0x0F0D1B2A),
      child: Column(
        children: [
          Semantics(
            label:
                'Progress: ${progress.done} of 5 steps done'
                '${progress.current == null ? '' : ', now ${_steps[progress.current!.index].$2}'}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  Expanded(
                    child: _Step(
                      label: _steps[i].$2,
                      icon: _steps[i].$3,
                      status: statuses[i],
                      leftLine: i == 0 ? null : lineOf(i),
                      rightLine: i == _steps.length - 1 ? null : lineOf(i + 1),
                    ),
                  ),
              ],
            ),
          ),
          if (stage == TripStage.paymentDue && holdUntil != null) ...[
            const SizedBox(height: 14),
            HoldCountdown(until: holdUntil!, onExpired: onHoldExpired),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.icon,
    required this.status,
    required this.leftLine,
    required this.rightLine,
  });

  final String label;
  final IconData icon;
  final TripStepStatus status;
  final Color? leftLine;
  final Color? rightLine;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (status) {
      TripStepStatus.done => (AppColors.ink, AppColors.paper, AppColors.ink),
      TripStepStatus.current => (
        AppColors.accent,
        AppColors.ink,
        AppColors.accent,
      ),
      TripStepStatus.muted => (
        AppColors.ink,
        AppColors.paper,
        AppColors.divider,
      ),
      TripStepStatus.upcoming => (
        AppColors.paper,
        AppColors.textFaint,
        AppColors.divider,
      ),
    };
    final strong =
        status == TripStepStatus.done || status == TripStepStatus.current;
    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 13,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: leftLine ?? Colors.transparent,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: rightLine ?? Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 2),
                  boxShadow: status == TripStepStatus.current
                      ? const [
                          BoxShadow(color: Color(0x2EFF5A1F), spreadRadius: 5),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  status == TripStepStatus.done ? Symbols.check_rounded : icon,
                  size: 15,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: AppTypography.body(
            11,
            weight: status == TripStepStatus.current
                ? FontWeight.w800
                : FontWeight.w600,
            color: strong ? AppColors.ink : AppColors.textFaint,
          ),
        ),
      ],
    );
  }
}

/// "Fare held for 23:41:10", ticking every second. Calls [onExpired] once
/// when it reaches zero.
class HoldCountdown extends StatefulWidget {
  const HoldCountdown({super.key, required this.until, this.onExpired});

  final DateTime until;
  final VoidCallback? onExpired;

  @override
  State<HoldCountdown> createState() => _HoldCountdownState();
}

class _HoldCountdownState extends State<HoldCountdown> {
  Timer? _timer;
  bool _fired = false;

  Duration get _left => widget.until.difference(DateTime.now());

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(HoldCountdown old) {
    super.didUpdateWidget(old);
    if (old.until != widget.until) _fired = false;
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    if (!_fired && _left <= Duration.zero) {
      _fired = true;
      widget.onExpired?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    final ended = left <= Duration.zero;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.timer_rounded,
            size: 18,
            color: AppColors.accentOnTint,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: ended ? 'Fare hold ended' : 'Fare held for ',
                children: [
                  if (!ended)
                    TextSpan(
                      text: Fmt.countdown(left),
                      style: AppTypography.number(
                        13,
                        color: AppColors.accentOnTint,
                        weight: FontWeight.w700,
                        tracking: 0,
                      ),
                    ),
                ],
              ),
              style: AppTypography.body(
                13,
                color: AppColors.accentOnTint,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
