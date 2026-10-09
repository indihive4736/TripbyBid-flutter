import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// An orange radial glow on the backdrop.
final class BackdropGlow {
  const BackdropGlow({
    required this.center,
    required this.diameter,
    required this.opacity,
  });

  /// Centre of the glow, relative to the backdrop (`Alignment` coordinates).
  final Alignment center;
  final double diameter;
  final double opacity;
}

/// Full-screen navy gradient (165°) with faint concentric rings and orange
/// glows — the splash and welcome backgrounds.
class InkBackdrop extends StatelessWidget {
  const InkBackdrop({
    super.key,
    required this.ringCenter,
    required this.glows,
    required this.child,
  });

  /// Centre of the concentric ring texture.
  final Alignment ringCenter;
  final List<BackdropGlow> glows;
  final Widget child;

  static const _gradient = LinearGradient(
    begin: Alignment(-0.26, -1),
    end: Alignment(0.26, 1),
    colors: [AppColors.inkRaised, AppColors.ink, AppColors.inkDeep],
    stops: [0, 0.5, 1],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _gradient),
      child: CustomPaint(
        painter: _BackdropPainter(ringCenter: ringCenter, glows: glows),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.ringCenter, required this.glows});

  final Alignment ringCenter;
  final List<BackdropGlow> glows;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.clipRect(bounds);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);
    final center = ringCenter.withinRect(bounds);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);
    for (var r = 28.0; r < maxR; r += 28) {
      canvas.drawCircle(center, r, ring);
    }

    for (final glow in glows) {
      final c = glow.center.withinRect(bounds);
      final radius = glow.diameter / 2;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: glow.opacity),
              AppColors.accent.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.ringCenter != ringCenter || old.glows != glows;
}

/// Gently bobs [child] up and down (the design's floating badges).
/// Still when the platform asks for reduced motion.
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 3200),
    this.delay = Duration.zero,
    this.distance = 8,
  });

  final Widget child;
  final Duration period;
  final Duration delay;
  final double distance;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  bool _started = false;
  Timer? _delay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _delay?.cancel();
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      if (_started || widget.delay == Duration.zero) {
        _controller.repeat();
      } else {
        _delay = Timer(widget.delay, () {
          if (mounted) _controller.repeat();
        });
      }
      _started = true;
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 0 → -distance → 0 with an ease-in-out on each half.
        final t = _controller.value;
        final half = t < 0.5 ? t * 2 : (1 - t) * 2;
        final dy = -widget.distance * Curves.easeInOut.transform(half);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}
