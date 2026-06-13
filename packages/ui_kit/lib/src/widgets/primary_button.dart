import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A primary call-to-action button with premium gradient and scale animations.
class PrimaryButton extends StatelessWidget {
  /// Creates a [PrimaryButton].
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  /// The button label.
  final String label;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether the button should expand to full width.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;

    final glowShadow = BoxShadow(
      color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    );

    final buttonDecoration = BoxDecoration(
      gradient: isEnabled
          ? const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryContainer],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
      color: isEnabled ? null : theme.disabledColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
      boxShadow: isEnabled ? [glowShadow] : null,
    );

    Widget childWidget = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: isEnabled ? AppColors.white : theme.disabledColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isEnabled ? AppColors.white : theme.disabledColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );

    Widget innerButton = Container(
      height: 48,
      decoration: buttonDecoration,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: childWidget,
          ),
        ),
      ),
    );

    Widget mainButton = isExpanded
        ? SizedBox(width: double.infinity, child: innerButton)
        : innerButton;

    return _TapScaleWrapper(
      enabled: isEnabled,
      child: mainButton,
    );
  }
}

class _TapScaleWrapper extends StatefulWidget {
  const _TapScaleWrapper({
    required this.child,
    required this.enabled,
  });

  final Widget child;
  final bool enabled;

  @override
  State<_TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<_TapScaleWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.enabled ? (_) => _controller.forward() : null,
      onTapUp: widget.enabled ? (_) => _controller.reverse() : null,
      onTapCancel: widget.enabled ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
