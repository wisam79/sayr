import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A styled text field with label, hint, and error support.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
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

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final TextCapitalization textCapitalization;
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
