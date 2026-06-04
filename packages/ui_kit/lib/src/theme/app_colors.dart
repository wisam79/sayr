import 'package:flutter/material.dart';

/// Sayr color palette - Material 3 seed-based with custom overrides.
class AppColors {
  AppColors._();

  /// Primary brand color (deep blue).
  static const Color primary = Color(0xFF1E5BFF);

  /// Secondary brand color (green).
  static const Color secondary = Color(0xFF10B981);

  /// Success color.
  static const Color success = Color(0xFF22C55E);

  /// Warning color.
  static const Color warning = Color(0xFFF59E0B);

  /// Error color.
  static const Color error = Color(0xFFEF4444);

  /// Info color.
  static const Color info = Color(0xFF3B82F6);

  /// Primary text color.
  static const Color textPrimary = Color(0xFF111827);

  /// Secondary text color.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Muted/disabled text color.
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Background color.
  static const Color background = Color(0xFFF9FAFB);

  /// Dark background.
  static const Color backgroundDark = Color(0xFF111827);

  /// Surface color (cards, sheets).
  static const Color surface = Color(0xFFFFFFFF);

  /// Border color.
  static const Color border = Color(0xFFE5E7EB);

  /// Divider color.
  static const Color divider = Color(0xFFF3F4F6);

  /// White.
  static const Color white = Color(0xFFFFFFFF);

  /// Black.
  static const Color black = Color(0xFF000000);

  /// Transparent.
  static const Color transparent = Color(0x00000000);

  /// Status colors for trip states.
  static const Color statusScheduled = Color(0xFF6B7280);
  static const Color statusDriverWaiting = Color(0xFFF59E0B);
  static const Color statusInTransit = Color(0xFF1E5BFF);
  static const Color statusCompleted = Color(0xFF22C55E);
  static const Color statusAbsent = Color(0xFFEF4444);
  static const Color statusCancelled = Color(0xFF9CA3AF);
}
