import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cream card with a hairline border — the design's default container.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.color = AppColors.card,
    this.borderColor = AppColors.hairline,
    this.borderWidth = 1,
    this.shadow = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  /// The soft drop shadow used on list cards.
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor, width: borderWidth),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: ShapeDecoration(
        shape: shape,
        shadows: shadow
            ? const [
                BoxShadow(
                  color: Color(0x660D1B2A),
                  offset: Offset(0, 14),
                  blurRadius: 30,
                  spreadRadius: -24,
                ),
              ]
            : null,
      ),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rounded square holding an icon on a tint — used in menus and quick actions.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.tint,
    this.size = 40,
    this.color = AppColors.ink,
    this.fill = false,
  });

  final IconData icon;
  final Color tint;
  final double size;
  final Color color;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: color, fill: fill ? 1 : 0),
    );
  }
}

/// Initials on a coloured rounded square (agents, travellers, the user).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.color,
    this.gradient,
    this.online = false,
  });

  final String name;
  final double size;
  final Color? color;
  final Gradient? gradient;

  /// Green presence dot.
  final bool online;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradient == null
                  ? (color ?? AppColors.avatarFor(name))
                  : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(size * 0.33),
            ),
            child: Text(
              initialsOf(name),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.33,
                color: AppColors.ink,
              ),
            ),
          ),
          if (online)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.paper, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
