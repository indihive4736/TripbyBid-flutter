import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonStyle {
  /// Orange gradient — the main call to action.
  accent,

  /// Navy gradient — strong secondary action on paper.
  ink,

  /// Transparent with a light border — secondary action on ink panels.
  outlineOnInk,

  /// Transparent with a dark border — secondary action on paper.
  outline,

  /// Solid danger red.
  danger,
}

/// Full-width pill button from the design (58 px, radius 19).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.accent,
    this.icon,
    this.leadingIcon,
    this.loading = false,
    this.height = 58,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;

  /// Trailing icon (the design's usual `arrow_forward`).
  final IconData? icon;
  final IconData? leadingIcon;
  final bool loading;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (decoration, foreground) = _look(enabled);
    final radius = BorderRadius.circular(height * 0.33);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: foreground,
            ),
          )
        else ...[
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 19, color: foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                height > 50 ? 16 : 15,
                color: foreground,
                weight: FontWeight.w800,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 19, color: foreground),
          ],
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: height,
        padding: EdgeInsets.symmetric(horizontal: expand ? 16 : 24),
        decoration: decoration.copyWith(borderRadius: radius),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: content,
          ),
        ),
      ),
    );
  }

  (BoxDecoration, Color) _look(bool enabled) {
    if (!enabled && !loading) {
      return (
        const BoxDecoration(color: AppColors.disabled),
        const Color(0xFF6B7482),
      );
    }
    return switch (style) {
      AppButtonStyle.accent => (
        const BoxDecoration(
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: Color(0xE6FF5A1F),
              offset: Offset(0, 14),
              blurRadius: 26,
              spreadRadius: -12,
            ),
          ],
        ),
        AppColors.ink,
      ),
      AppButtonStyle.ink => (
        const BoxDecoration(
          gradient: AppColors.inkGradient,
          boxShadow: [
            BoxShadow(
              color: Color(0xCC0D1B2A),
              offset: Offset(0, 14),
              blurRadius: 26,
              spreadRadius: -12,
            ),
          ],
        ),
        AppColors.onInk,
      ),
      AppButtonStyle.outlineOnInk => (
        BoxDecoration(
          border: Border.all(color: const Color(0x38FFFFFF), width: 1.5),
        ),
        AppColors.onInk,
      ),
      AppButtonStyle.outline => (
        BoxDecoration(
          border: Border.all(color: const Color(0x260D1B2A), width: 1.5),
        ),
        AppColors.ink,
      ),
      AppButtonStyle.danger => (
        const BoxDecoration(color: AppColors.danger),
        Colors.white,
      ),
    };
  }
}

/// Square icon button (back, close, share…) — 44 px, radius 15.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.onInk = false,
    this.filled = false,
    this.size = 44,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  /// Translucent white on navy panels instead of a cream card.
  final bool onInk;

  /// Solid navy background (e.g. the chat button on an agent card).
  final bool filled;
  final double size;

  /// Orange unread dot.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.34);
    final (bg, fg, border) = filled
        ? (AppColors.ink, AppColors.onInk, null)
        : onInk
        ? (const Color(0x1AFFFFFF), AppColors.onInk, null)
        : (
            AppColors.card,
            AppColors.ink,
            Border.all(color: AppColors.hairline),
          );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: border?.top ?? BorderSide.none,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: size * 0.5, color: fg),
                if (badge)
                  Positioned(
                    top: size * 0.22,
                    right: size * 0.24,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
