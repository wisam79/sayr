import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A premium glassmorphism card with backdrop blur, subtle border, and shadow.
///
/// Wraps [child] in a frosted-glass container. Tappable when [onTap] is set.
class GlassCard extends StatelessWidget {
  /// Creates a [GlassCard].
  const GlassCard({
    required this.child,
    super.key,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.blurSigma = 10,
    this.borderOpacity = 0.06,
    this.shadowOpacity = 0.12,
    this.onTap,
  });

  /// The content to display inside the glass card.
  final Widget child;

  /// The border radius of the card (defaults to [AppSpacing.cardRadius]).
  final double? borderRadius;

  /// The padding around [child] (defaults to [AppSpacing.lg]).
  final EdgeInsetsGeometry? padding;

  /// The margin around the card.
  final EdgeInsetsGeometry? margin;

  /// The background tint color (defaults to [Theme.of(context).cardColor]).
  final Color? color;

  /// The blur sigma for the backdrop filter.
  final double blurSigma;

  /// The opacity of the border stroke (0.0–1.0).
  final double borderOpacity;

  /// The opacity of the box shadow (0.0–1.0).
  final double shadowOpacity;

  /// Optional tap handler — makes the card tappable with a ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.cardRadius;
    final cardColor = Theme.of(context).cardColor;

    // Use alpha blending to combine custom tint with base card color.
    // This preserves high opacity (blocking noise) for text contrast.
    final baseColor1 = cardColor.withValues(alpha: 0.94);
    final baseColor2 = cardColor.withValues(alpha: 0.78);

    final color1 =
        color != null ? Color.alphaBlend(color!, baseColor1) : baseColor1;
    final color2 =
        color != null ? Color.alphaBlend(color!, baseColor2) : baseColor2;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: borderOpacity),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: shadowOpacity * (isDark ? 0.6 : 0.4)),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: card,
    );
  }
}
