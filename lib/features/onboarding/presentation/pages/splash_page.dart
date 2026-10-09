import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/headings.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../widgets/ink_backdrop.dart';

/// A1 — the brand moment shown while the stored session is restored
/// (`AuthUnknown`). The router moves on; this page never navigates.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: InkBackdrop(
          ringCenter: const Alignment(0, -0.08),
          glows: const [
            BackdropGlow(
              center: Alignment(0, -0.2),
              diameter: 520,
              opacity: 0.5,
            ),
          ],
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Semantics(
                  label: 'TripByBid. Name your price. Let agents bid.',
                  excludeSemantics: true,
                  child: const _Brand(),
                ),
                const Spacer(),
                Semantics(label: 'Loading', child: const _LoadingBar()),
                const SizedBox(height: 14),
                const Eyebrow(
                  'Made in India · v1.0',
                  color: AppColors.onInkFaint,
                ),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Floating(child: BrandMark(size: 112, glow: true)),
          const SizedBox(height: 22),
          Text(
            'TripByBid',
            textAlign: TextAlign.center,
            style: AppTypography.display(40, color: AppColors.onInk),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppTypography.body(16, color: AppColors.onInkSecondary),
              children: [
                const TextSpan(text: 'Name your price. '),
                TextSpan(
                  text: 'Let agents bid.',
                  style: AppTypography.accent(19, color: AppColors.accentSoft),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 120×4 track whose orange fill sweeps in from the left, on a loop.
class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  static const _curve = Cubic(0.6, 0, 0.2, 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.6;
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 120,
        height: 4,
        color: const Color(0x1FFFFFFF),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scaleX: _curve.transform(_controller.value),
            alignment: Alignment.centerLeft,
            child: child,
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              gradient: LinearGradient(
                colors: [AppColors.accentLight, Color(0xFFFF5418)],
              ),
            ),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
