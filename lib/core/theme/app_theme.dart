import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// The design is light-only: cream paper, navy ink, orange accent.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.ink,
      onPrimary: AppColors.onInk,
      secondary: AppColors.accent,
      onSecondary: AppColors.ink,
      error: AppColors.danger,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: AppColors.hairline, width: 1.5),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: AppTypography.sans,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        hintStyle: AppTypography.body(16, color: AppColors.textFaint),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorStyle: AppTypography.body(12, color: AppColors.danger),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accentTint,
        selectionHandleColor: AppColors.accent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.sheet,
        modalBackgroundColor: AppColors.sheet,
        showDragHandle: true,
        dragHandleColor: Color(0x2E0D1B2A),
        dragHandleSize: Size(40, 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.body(
          14,
          color: AppColors.onInk,
          weight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
