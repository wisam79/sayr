import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A primary call-to-action button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  /// The button label.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether the button should expand to full width.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
