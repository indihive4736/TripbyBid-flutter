import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_buttons.dart';

/// The bottom bar over a paper fade: a square secondary button and the
/// stage's primary action.
class DetailActionBar extends StatelessWidget {
  const DetailActionBar({
    super.key,
    required this.secondaryIcon,
    required this.secondaryTooltip,
    required this.onSecondary,
    required this.label,
    required this.onPrimary,
    this.icon,
    this.style = AppButtonStyle.accent,
    this.loading = false,
  });

  final IconData secondaryIcon;
  final String secondaryTooltip;
  final VoidCallback onSecondary;
  final String label;
  final IconData? icon;
  final AppButtonStyle style;
  final VoidCallback? onPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottom > 0 ? bottom + 8 : 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00F3EDE3), AppColors.paper],
          stops: [0, 0.32],
        ),
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: secondaryIcon,
            tooltip: secondaryTooltip,
            size: 56,
            onPressed: onSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              label: label,
              leadingIcon: icon,
              style: style,
              height: 56,
              loading: loading,
              onPressed: onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
