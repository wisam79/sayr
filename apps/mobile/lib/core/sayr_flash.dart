import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Material 3 styled flash messages (replaces ScaffoldMessenger.showSnackBar).
class SayrFlash {
  SayrFlash._();

  /// Show success message.
  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      AppColors.success,
      Icons.check_circle,
    );
  }

  /// Show error message.
  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      AppColors.error,
      Icons.error,
    );
  }

  /// Show info message.
  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      AppColors.info,
      Icons.info,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    showFlash<void>(
      context: context,
      duration: const Duration(seconds: 3),
      builder: (context, controller) {
        return Flash(
          controller: controller,
          position: FlashPosition.top,
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(8),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
