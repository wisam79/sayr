import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A secondary outlined button.
class SecondaryButton extends StatelessWidget {
  /// Creates a [SecondaryButton].
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
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
    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
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
            ),
    );

    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
