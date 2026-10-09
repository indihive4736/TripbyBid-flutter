import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_buttons.dart';
import '../trip_detail_cubit.dart';

/// Opens a bottom sheet (sheet colour, drag handle, slide-up) that can read
/// the screen's [TripDetailCubit].
Future<T?> showDetailSheet<T>(BuildContext context, Widget sheet) {
  final cubit = context.read<TripDetailCubit>();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: const Color(0x800D1B2A),
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: sheet,
        ),
      ),
    ),
  );
}

/// The 22 px sheet title with an optional line under it.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.sub, this.trailing});

  final String title;
  final String? sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.body(
                  22,
                  weight: FontWeight.w800,
                ).copyWith(letterSpacing: -0.03 * 22),
              ),
            ),
            ?trailing,
          ],
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(
            sub!,
            style: AppTypography.body(14, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Selectable pill (reasons, quick tags).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.ink : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.ink : const Color(0x1F0D1B2A),
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Text(
                label,
                style: AppTypography.body(
                  13,
                  weight: FontWeight.w600,
                  color: selected ? AppColors.paper : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error inside a sheet.
class SheetError extends StatelessWidget {
  const SheetError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Symbols.error_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                13,
                weight: FontWeight.w600,
                color: AppColors.accentOnTint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks to confirm a step; resolves to true when confirmed.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Not now',
  bool destructive = true,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    barrierColor: const Color(0x800D1B2A),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(title, sub: message),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: cancelLabel,
                  style: AppButtonStyle.outline,
                  height: 54,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  style: destructive
                      ? AppButtonStyle.danger
                      : AppButtonStyle.accent,
                  height: 54,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}
