import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Navy gradient panel with an orange glow and faint concentric rings —
/// the hero surface used for trip cards, budgets and screen headers.
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.glow = Alignment.topRight,
    this.glowSize = 280,
    this.glowOpacity = 0.45,
    this.rings = true,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Where the orange glow sits (it overflows the panel edge).
  final Alignment glow;
  final double glowSize;
  final double glowOpacity;
  final bool rings;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: AppColors.panelGradient,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0xCC0D1B2A),
                  offset: Offset(0, 30),
                  blurRadius: 50,
                  spreadRadius: -28,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: _PanelPainter(
            glow: glow,
            glowSize: glowSize,
            glowOpacity: glowOpacity,
            rings: rings,
          ),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.onInk),
              child: IconTheme.merge(
                data: const IconThemeData(color: AppColors.onInk),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter({
    required this.glow,
    required this.glowSize,
    required this.glowOpacity,
    required this.rings,
  });

  final Alignment glow;
  final double glowSize;
  final double glowOpacity;
  final bool rings;

  @override
  void paint(Canvas canvas, Size size) {
    final center = glow.withinRect(Offset.zero & size);
    final radius = glowSize / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: glowOpacity),
            AppColors.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (!rings) return;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);
    for (var r = 22.0; r < maxR; r += 22) {
      canvas.drawCircle(center, r, ring);
    }
  }

  @override
  bool shouldRepaint(_PanelPainter old) =>
      old.glow != glow ||
      old.glowSize != glowSize ||
      old.glowOpacity != glowOpacity ||
      old.rings != rings;
}

/// The "b" brand tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.glow = false});

  final double size;

  /// Orange drop glow used on the splash screen.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.inkRaised, AppColors.inkDeep],
        ),
        border: Border.all(color: const Color(0x24FFFFFF), width: 1.5),
        boxShadow: glow
            ? const [
                BoxShadow(
                  color: Color(0x8CFF5A1F),
                  offset: Offset(0, 30),
                  blurRadius: 60,
                  spreadRadius: -20,
                ),
              ]
            : null,
      ),
      child: Text(
        'b',
        style: AppTypography.accent(
          size * 0.68,
          color: AppColors.accent,
        ).copyWith(height: 1.05),
      ),
    );
  }
}

/// Horizontal dashed rule (ticket perforation, route lines).
class DashedLine extends StatelessWidget {
  const DashedLine({
    super.key,
    this.color = AppColors.divider,
    this.thickness = 1.5,
    this.dash = 5,
    this.gap = 4,
  });

  final Color color;
  final double thickness;
  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(color, thickness, dash, gap)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.thickness, this.dash, this.gap);

  final Color color;
  final double thickness;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.thickness != thickness;
}
