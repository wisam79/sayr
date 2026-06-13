import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';
import 'package:sayr_ui_kit/src/widgets/glass_card.dart';
import 'package:sayr_ui_kit/src/widgets/primary_button.dart';
import 'package:sayr_ui_kit/src/widgets/secondary_button.dart';

/// A premium, glassmorphic custom dialog with optional header icon,
/// title, subtitle, scrollable content area, and action buttons.
class SayrDialog extends StatelessWidget {
  /// Creates a [SayrDialog].
  const SayrDialog({
    required this.title,
    super.key,
    this.subtitle,
    this.content,
    this.headerIcon,
    this.headerIconColor,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.isPrimaryLoading = false,
    this.isSecondaryLoading = false,
  });

  /// The title of the dialog.
  final String title;

  /// Optional subtitle or description.
  final String? subtitle;

  /// The content to display inside the dialog.
  final Widget? content;

  /// Optional header icon displayed at the top.
  final IconData? headerIcon;

  /// The color of the header icon (defaults to [AppColors.primary]).
  final Color? headerIconColor;

  /// The label for the primary action button.
  final String? primaryLabel;

  /// The callback when the primary button is pressed.
  final VoidCallback? onPrimaryPressed;

  /// The label for the secondary action button.
  final String? secondaryLabel;

  /// The callback when the secondary button is pressed.
  final VoidCallback? onSecondaryPressed;

  /// Whether the primary button is in a loading state.
  final bool isPrimaryLoading;

  /// Whether the secondary button is in a loading state.
  final bool isSecondaryLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = headerIconColor ?? AppColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - (AppSpacing.xl * 4),
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (headerIcon != null) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      headerIcon,
                      color: iconColor,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: headerIcon != null
                    ? TextAlign.center
                    : TextAlign.start,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: headerIcon != null
                      ? TextAlign.center
                      : TextAlign.start,
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Flexible(
                  child: SingleChildScrollView(
                    child: content,
                  ),
                ),
              ],
              if (primaryLabel != null || secondaryLabel != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (secondaryLabel != null)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: primaryLabel != null ? AppSpacing.md : 0,
                          ),
                          child: SecondaryButton(
                            label: secondaryLabel!,
                            onPressed: onSecondaryPressed,
                            isLoading: isSecondaryLoading,
                          ),
                        ),
                      ),
                    if (primaryLabel != null)
                      Expanded(
                        child: PrimaryButton(
                          label: primaryLabel!,
                          onPressed: onPrimaryPressed,
                          isLoading: isPrimaryLoading,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
