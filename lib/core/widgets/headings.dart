import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Display heading with one italic serif accent word:
/// `lead` + *accent* + `trail` — e.g. "Welcome " *back.*
class DisplayHeading extends StatelessWidget {
  const DisplayHeading({
    super.key,
    required this.lead,
    required this.accent,
    this.trail = '',
    this.size = 40,
    this.color = AppColors.ink,
    this.accentColor = AppColors.accentDeep,
    this.textAlign = TextAlign.start,
  });

  final String lead;
  final String accent;
  final String trail;
  final double size;
  final Color color;
  final Color accentColor;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTypography.display(size, color: color).copyWith(height: 0.98),
        children: [
          TextSpan(text: lead),
          TextSpan(
            text: accent,
            style: AppTypography.accent(size * 1.02, color: accentColor),
          ),
          if (trail.isNotEmpty) TextSpan(text: trail),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

/// Uppercase mono label, optionally with a pulsing live dot.
class Eyebrow extends StatelessWidget {
  const Eyebrow(
    this.text, {
    super.key,
    this.color = AppColors.accentDeep,
    this.size = 11,
    this.live = false,
  });

  final String text;
  final Color color;
  final double size;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: AppTypography.eyebrow(size: size, color: color),
    );
    if (!live) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [const PulseDot(), const SizedBox(width: 8), label],
    );
  }
}

/// Section header: title on the left, optional action link on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(title, style: AppTypography.title(19))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                action!,
                style: AppTypography.body(
                  13,
                  color: AppColors.accentDeep,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Status pill with a leading dot: "● 3 bids", "● Confirmed".
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.dot = true,
    this.size = 11,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool dot;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.85, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            style: AppTypography.body(
              size,
              color: foreground,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The orange "live" dot with an expanding ring.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.size = 7});

  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
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
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.6 * (1 - t)),
                spreadRadius: 9 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
