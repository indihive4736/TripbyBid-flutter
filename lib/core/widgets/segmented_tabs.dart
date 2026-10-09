import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.count,
    this.badge,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// Faded number after the label ("Active 4").
  final int? count;

  /// Orange count bubble ("Bids ③").
  final int? badge;
}

/// Pill segmented control on a sunken track; the selected segment turns navy.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = 42,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(height * 0.42),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(child: _segment(option, option.value == selected)),
        ],
      ),
    );
  }

  Widget _segment(SegmentOption<T> option, bool on) {
    final fg = on ? AppColors.onInk : AppColors.ink;
    return Semantics(
      selected: on,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(option.value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: height,
          decoration: BoxDecoration(
            color: on ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(height * 0.33),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0xB30D1B2A),
                      offset: Offset(0, 8),
                      blurRadius: 16,
                      spreadRadius: -8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  option.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    height > 40 ? 14 : 13,
                    color: fg,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              if (option.count != null) ...[
                const SizedBox(width: 4),
                Text(
                  '${option.count}',
                  style: AppTypography.number(
                    12,
                    color: fg.withValues(alpha: 0.6),
                    tracking: 0,
                  ),
                ),
              ],
              if (option.badge != null && option.badge! > 0) ...[
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${option.badge}',
                    style: AppTypography.number(10, tracking: 0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
