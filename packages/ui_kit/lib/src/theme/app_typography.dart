import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';

/// Sayr typography - uses IBM Plex Sans Arabic font for Arabic-first design.
class AppTypography {
  AppTypography._();

  /// Base text theme for light mode.
  static TextTheme get light => _buildTextTheme(AppColors.textPrimary);

  /// Base text theme for dark mode.
  static TextTheme get dark => _buildTextTheme(AppColors.white);

  static TextTheme _buildTextTheme(Color baseColor) {
    return GoogleFonts.ibmPlexSansArabicTextTheme().copyWith(
      displayLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.ibmPlexSansArabic(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.ibmPlexSansArabic(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.ibmPlexSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.ibmPlexSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.ibmPlexSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.ibmPlexSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.ibmPlexSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.ibmPlexSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.ibmPlexSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.ibmPlexSansArabic(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.ibmPlexSansArabic(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.4,
      ),
    );
  }
}
