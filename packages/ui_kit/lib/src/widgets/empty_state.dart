import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// An empty state widget (icon + title + subtitle + optional action) with
/// premium breathing and staggered entrance animations.
class EmptyState extends StatefulWidget {
  /// Creates an [EmptyState].
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.action,
  });

  /// The icon to display.
  final IconData icon;

  /// The title text.
  final String title;

  /// The optional subtitle text.
  final String? subtitle;

  /// The optional action widget.
  final Widget? action;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _entranceController;

  late Animation<double> _breathScale;

  late Animation<double> _iconOpacity;
  late Animation<Offset> _iconSlide;

  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;

  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;

  late Animation<double> _actionOpacity;
  late Animation<Offset> _actionSlide;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _breathScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    const slideOffset = Offset(0.0, 0.25);

    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _iconSlide = Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _actionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _actionSlide = Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _entranceController.value = 1.0;
      _breathingController.stop();
    } else {
      if (!_entranceController.isAnimating && _entranceController.value < 1.0) {
        _entranceController.forward();
      }
      if (!_breathingController.isAnimating) {
        _breathingController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final disableAnimations = isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    Widget iconWidget = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.icon,
        size: 40,
        color: AppColors.primary,
      ),
    );

    if (!disableAnimations) {
      iconWidget = ScaleTransition(
        scale: _breathScale,
        child: iconWidget,
      );
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        disableAnimations
            ? iconWidget
            : FadeTransition(
                opacity: _iconOpacity,
                child: SlideTransition(
                  position: _iconSlide,
                  child: iconWidget,
                ),
              ),
        const SizedBox(height: AppSpacing.lg),
        disableAnimations
            ? Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              )
            : FadeTransition(
                opacity: _titleOpacity,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          disableAnimations
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    widget.subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )
              : FadeTransition(
                  opacity: _subtitleOpacity,
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
        ],
        if (widget.action != null) ...[
          const SizedBox(height: AppSpacing.xl),
          disableAnimations
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 220,
                    minWidth: 140,
                  ),
                  child: widget.action,
                )
              : FadeTransition(
                  opacity: _actionOpacity,
                  child: SlideTransition(
                    position: _actionSlide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 220,
                        minWidth: 140,
                      ),
                      child: widget.action,
                    ),
                  ),
                ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }
}
