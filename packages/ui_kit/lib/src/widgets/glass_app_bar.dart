import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';

/// A premium frosted glass AppBar with backdrop blur.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a [GlassAppBar].
  const GlassAppBar({
    required this.title,
    super.key,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.centerTitle = true,
  });

  /// The primary widget displayed in the app bar.
  final Widget title;

  /// A widget to display before the [title].
  final Widget? leading;

  /// Widgets to display after the [title] widget.
  final List<Widget>? actions;

  /// Background override color.
  final Color? backgroundColor;

  /// Whether the title should be centered.
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBgColor = backgroundColor ??
        (isDark
            ? AppColors.darkSurface.withValues(alpha: 0.82)
            : AppColors.surface.withValues(alpha: 0.82));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          title: title,
          leading: leading,
          actions: actions,
          centerTitle: centerTitle,
          backgroundColor: resolvedBgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
