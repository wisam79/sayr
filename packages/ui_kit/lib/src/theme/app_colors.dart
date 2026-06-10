import 'package:flutter/material.dart';

/// Sayr color palette - Material 3 seed-based with custom overrides.
class AppColors {
  AppColors._();

  /// Primary brand color (green).
  static const Color primary = Color(0xFF00875A);

  /// Primary Container color (slightly lighter green).
  static const Color primaryContainer = Color(0xFF0EA36E);

  /// Primary Fixed color (mint green accent).
  static const Color primaryFixed = Color(0xFFA6FFCC);

  /// Secondary brand color (deep blue).
  static const Color secondary = Color(0xFF1E5BFF);

  /// Success color.
  static const Color success = Color(0xFF00875A);

  /// Warning color.
  static const Color warning = Color(0xFFF59E0B);

  /// Error color.
  static const Color error = Color(0xFFBA1A1A);

  /// Info color.
  static const Color info = Color(0xFF555F6F);

  /// Primary text color.
  static const Color textPrimary = Color(0xFF151C27);

  /// Secondary text color.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Muted/disabled text color.
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Background color.
  static const Color background = Color(0xFFF9F9FF);

  /// Dark background.
  static const Color backgroundDark = Color(0xFF111827);

  /// Surface color (cards, sheets).
  static const Color surface = Color(0xFFFFFFFF);

  /// Dark surface color.
  static const Color darkSurface = Color(0xFF1F2937);

  /// Surface Container color (light blue/grey container background).
  static const Color surfaceContainer = Color(0xFFE7EEFE);

  /// Surface Variant color (neutral variant container background).
  static const Color surfaceVariant = Color(0xFFDCE2F3);

  /// Border color (Outline).
  static const Color border = Color(0xFF6F7973);

  /// Dark border color.
  static const Color borderDark = Color(0xFF374151);

  /// Divider color.
  static const Color divider = Color(0xFFE5E7EB);

  /// Dark divider color.
  static const Color dividerDark = Color(0xFF374151);

  /// White.
  static const Color white = Color(0xFFFFFFFF);

  /// Black.
  static const Color black = Color(0xFF000000);

  /// Transparent.
  static const Color transparent = Color(0x00000000);

  /// Status colors for trip states.
  /// Scheduled status.
  static const Color statusScheduled = Color(0xFF6B7280);

  /// Driver waiting status.
  static const Color statusDriverWaiting = Color(0xFFF59E0B);

  /// In transit status.
  static const Color statusInTransit = Color(0xFF1E5BFF);

  /// Completed status.
  static const Color statusCompleted = Color(0xFF22C55E);

  /// Absent status.
  static const Color statusAbsent = Color(0xFFEF4444);

  /// Cancelled status.
  static const Color statusCancelled = Color(0xFF9CA3AF);
}
