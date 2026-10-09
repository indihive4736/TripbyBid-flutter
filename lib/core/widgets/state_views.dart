import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_buttons.dart';

/// Centered message for empty, error and "nothing yet" states.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tint = AppColors.accentTint,
    this.iconColor = AppColors.accentOnTint,
  });

  /// The standard error state with a retry button.
  factory StateMessage.error({
    Key? key,
    required String message,
    required VoidCallback onRetry,
  }) => StateMessage(
    key: key,
    icon: Symbols.cloud_off_rounded,
    title: 'Something went wrong',
    message: message,
    actionLabel: 'Try again',
    onAction: onRetry,
    tint: AppColors.dangerTint,
    iconColor: AppColors.danger,
  );

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.title(17),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                14,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              style: AppButtonStyle.ink,
              height: 48,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-area loading spinner.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}
