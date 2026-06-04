import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Main app theme (Material 3).
class AppTheme {
  AppTheme._();

  /// Light theme.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTypography.light,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.light.titleLarge,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            ),
            textStyle: AppTypography.light.labelLarge,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: AppTypography.light.bodyMedium,
          hintStyle: AppTypography.light.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );

  /// Dark theme.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: AppTypography.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.dark.titleLarge,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}
