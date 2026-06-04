import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A styled text field with label, hint, and error support.
class AppTextField extends StatelessWidget {
  /// Creates an [AppTextField].
  const AppTextField({
    required this.label,
    super.key,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  /// The label text of the text field.
  final String label;

  /// The hint text of the text field.
  final String? hint;

  /// The text editing controller.
  final TextEditingController? controller;

  /// The field validator.
  final FormFieldValidator<String>? validator;

  /// The keyboard type.
  final TextInputType? keyboardType;

  /// The text input action.
  final TextInputAction? textInputAction;

  /// Whether the text is obscured.
  final bool obscureText;

  /// The optional prefix icon.
  final IconData? prefixIcon;

  /// The optional suffix widget.
  final Widget? suffixIcon;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when text is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field is focused automatically.
  final bool autofocus;

  /// The maximum lines.
  final int maxLines;

  /// The maximum length.
  final int? maxLength;

  /// Whether the field is enabled.
  final bool enabled;

  /// Text capitalization style.
  final TextCapitalization textCapitalization;

  /// Custom input formatters.
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          autofocus: autofocus,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
