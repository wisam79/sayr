import 'package:flutter/material.dart';

/// Sayr color palette - Material 3 seed-based with custom overrides.
class AppColors {
  AppColors._();

  /// Primary brand color (Teal - Light Mode).
  static const Color primary = Color(0xFF0D9488);

  /// Primary brand color (Teal - Dark Mode).
  static const Color primaryDark = Color(0xFF2DD4BF);

  /// Primary Container color (Light Mode).
  static const Color primaryContainer = Color(0xFFF0FDFA);

  /// Primary Container color (Dark Mode).
  static const Color primaryContainerDark = Color(0xFF042F2E);

  /// Primary Fixed color (mint green accent).
  static const Color primaryFixed = Color(0xFFA6FFCC);

  /// Secondary brand color (Slate - Light Mode).
  static const Color secondary = Color(0xFF0F172A);

  /// Secondary brand color (Sky - Dark Mode).
  static const Color secondaryDark = Color(0xFF38BDF8);

  /// Success color.
  static const Color success = Color(0xFF10B981);

  /// Warning color.
  static const Color warning = Color(0xFFF59E0B);

  /// Error color.
  static const Color error = Color(0xFFEF4444);

  /// Info color.
  static const Color info = Color(0xFF64748B);

  /// Primary text color.
  static const Color textPrimary = Color(0xFF0F172A);

  /// Secondary text color.
  static const Color textSecondary = Color(0xFF475569);

  /// Muted/disabled text color.
  static const Color textMuted = Color(0xFF94A3B8);

  /// Background color (Light Mode).
  static const Color background = Color(0xFFF8FAFC);

  /// Dark background (Dark Mode - Space Obsidian).
  static const Color backgroundDark = Color(0xFF090D16);

  /// Surface color (cards, sheets - Light Mode).
  static const Color surface = Color(0xFFFFFFFF);

  /// Dark surface color (cards, sheets - Dark Mode).
  static const Color darkSurface = Color(0xFF121824);

  /// Surface Container color (light blue/grey container background).
  static const Color surfaceContainer = Color(0xFFF1F5F9);

  /// Surface Variant color (neutral variant container background).
  static const Color surfaceVariant = Color(0xFFE2E8F0);

  /// Border color (Outline - Light Mode).
  static const Color border = Color(0xFFCBD5E1);

  /// Dark border color (Outline - Dark Mode).
  static const Color borderDark = Color(0xFF334155);

  /// Divider color (Light Mode).
  static const Color divider = Color(0xFFE2E8F0);

  /// Dark divider color (Dark Mode).
  static const Color dividerDark = Color(0xFF1E293B);

  /// White.
  static const Color white = Color(0xFFFFFFFF);

  /// Black.
  static const Color black = Color(0xFF000000);

  /// Transparent.
  static const Color transparent = Color(0x00000000);

  /// Status colors for trip states.
  /// Scheduled status.
  static const Color statusScheduled = Color(0xFF64748B);

  /// Driver waiting status.
  static const Color statusDriverWaiting = Color(0xFFF59E0B);

  /// In transit status.
  static const Color statusInTransit = Color(0xFF0EA5E9);

  /// Completed status.
  static const Color statusCompleted = Color(0xFF10B981);

  /// Absent status.
  static const Color statusAbsent = Color(0xFFEF4444);

  /// Cancelled status.
  static const Color statusCancelled = Color(0xFF94A3B8);
}
