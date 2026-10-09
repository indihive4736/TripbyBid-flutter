import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Labelled text field from the design: label above a 54 px rounded field.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.helper,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Small grey line under the field when there is no error.
  final String? helper;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body(13, weight: FontWeight.w600)),
        const SizedBox(height: 7),
        TextFormField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: AppTypography.body(16, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: AppTypography.body(12, color: AppColors.textTertiary),
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
