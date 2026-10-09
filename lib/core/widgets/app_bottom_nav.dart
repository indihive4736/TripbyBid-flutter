import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.label,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final bool badge;
}

/// The floating navy tab bar with a raised orange "new request" button in
/// the middle. [items] are the four tabs (two either side of the button).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onCreate,
  }) : assert(items.length == 4);

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  /// Height of the bar plus its bottom margin, for content padding.
  static const double reservedHeight = 72 + 26;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tab(0),
                _tab(1),
                _CreateButton(onPressed: onCreate),
                _tab(2),
                _tab(3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index) {
    final item = items[index];
    final on = index == currentIndex;
    final fg = on ? AppColors.accentSoft : AppColors.onInkFaint;
    return Semantics(
      selected: on,
      button: true,
      label: item.label,
      child: GestureDetector(
        onTap: () => onSelect(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: on ? const Color(0x1AFFFFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(item.icon, size: 23, color: fg, fill: on ? 1 : 0),
                    if (item.badge)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: AppTypography.body(
                    10,
                    color: fg,
                    weight: FontWeight.w700,
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

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New request',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0xE6FF5A1F),
                offset: Offset(0, 10),
                blurRadius: 20,
                spreadRadius: -8,
              ),
            ],
          ),
          child: const Icon(
            Symbols.add_rounded,
            size: 28,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
