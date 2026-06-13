import 'dart:ui';

import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

enum _FlashSeverity {
  success,
  error,
  warning,
  info,
}

/// Material 3 styled glassmorphic flash messages (replaces ScaffoldMessenger.showSnackBar).
class SayrFlash {
  SayrFlash._();

  /// Show success message.
  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      _FlashSeverity.success,
    );
  }

  /// Show error message.
  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      _FlashSeverity.error,
    );
  }

  /// Show warning message.
  static void warning(BuildContext context, String message) {
    _show(
      context,
      message,
      _FlashSeverity.warning,
    );
  }

  /// Show info message.
  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      _FlashSeverity.info,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    _FlashSeverity severity,
  ) {
    // Trigger native haptic feedback based on severity
    switch (severity) {
      case _FlashSeverity.success:
        HapticFeedback.successNotification();
      case _FlashSeverity.error:
        HapticFeedback.errorNotification();
      case _FlashSeverity.warning:
        HapticFeedback.mediumImpact();
      case _FlashSeverity.info:
        HapticFeedback.lightImpact();
    }

    final color = switch (severity) {
      _FlashSeverity.success => AppColors.success,
      _FlashSeverity.error => AppColors.error,
      _FlashSeverity.warning => AppColors.warning,
      _FlashSeverity.info => AppColors.info,
    };

    final icon = switch (severity) {
      _FlashSeverity.success => Icons.check_circle_rounded,
      _FlashSeverity.error => Icons.error_outline_rounded,
      _FlashSeverity.warning => Icons.warning_amber_rounded,
      _FlashSeverity.info => Icons.info_outline_rounded,
    };

    showFlash<void>(
      context: context,
      duration: const Duration(seconds: 4),
      builder: (context, controller) {
        final theme = Theme.of(context);
        final cardColor = theme.cardColor;

        // Determine if current locale is Arabic
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final title = switch (severity) {
          _FlashSeverity.success => isArabic ? 'نجاح' : 'Success',
          _FlashSeverity.error => isArabic ? 'خطأ' : 'Error',
          _FlashSeverity.warning => isArabic ? 'تنبيه' : 'Warning',
          _FlashSeverity.info => isArabic ? 'توضيح' : 'Info',
        };

        // Blend severity color tint with base card color for rich frosted glass look
        final baseColor = cardColor.withValues(alpha: 0.9);
        final tintColor = color.withValues(alpha: 0.08);
        final blendedColor = Color.alphaBlend(tintColor, baseColor);

        return Flash(
          controller: controller,
          position: FlashPosition.top,
          dismissDirections: const [
            FlashDismissDirection.vertical,
            FlashDismissDirection.endToStart,
            FlashDismissDirection.startToEnd,
          ],
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: blendedColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Severity Icon Badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Title and Message details
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.9),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Close Dismiss Button
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.dismiss(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
