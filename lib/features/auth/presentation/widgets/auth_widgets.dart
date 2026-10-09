import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';

/// Paper background with a soft orange glow in one corner.
class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.glow = const Alignment(1.6, -1.25),
    this.glowOpacity = 0.22,
  });

  final Widget child;
  final Alignment glow;
  final double glowOpacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GlowPainter(glow, glowOpacity), child: child);
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.glow, this.opacity);

  final Alignment glow;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = glow.withinRect(Offset.zero & size);
    const radius = 220.0;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: opacity),
            AppColors.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.glow != glow || old.opacity != opacity;
}

/// The cream back button; falls back to the welcome screen when there is
/// nothing to pop.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.fallback = AppRoutes.welcome});

  final String fallback;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Symbols.arrow_back_rounded,
      tooltip: 'Back',
      onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
    );
  }
}

/// "New to TripByBid? **Sign up**" — the whole line is the tap target.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$prompt $action',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Text.rich(
              TextSpan(
                style: AppTypography.body(15, color: AppColors.textSecondary),
                children: [
                  TextSpan(text: '$prompt '),
                  TextSpan(
                    text: action,
                    style: AppTypography.body(
                      15,
                      color: AppColors.accentDeep,
                      weight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Show/hide toggle for password fields.
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      onPressed: onToggle,
      icon: Icon(
        obscured ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
        size: 20,
      ),
    );
  }
}

/// Inline notice above a form (session expired, errors).
class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.message,
    this.icon = Symbols.info_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accentOnTint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body(
                  14,
                  color: AppColors.accentOnTint,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
