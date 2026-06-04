import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Sayr typography - uses Cairo font for Arabic-first design.
class AppTypography {
  AppTypography._();

  /// Base text theme for light mode.
  static TextTheme get light => _buildTextTheme(AppColors.textPrimary);

  /// Base text theme for dark mode.
  static TextTheme get dark => _buildTextTheme(AppColors.white);

  static TextTheme _buildTextTheme(Color baseColor) {
    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
    );
  }
}
