import 'package:flutter/material.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isHorizontal = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isHorizontal;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -3, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 67,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _scaleController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
      );
      _bounceController.forward(from: 0);
    }
    widget.onTap();
  }

  void _handleTapCancel() {
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final Widget iconContainer = Container(
      width: widget.isHorizontal ? 36 : 44,
      height: widget.isHorizontal ? 36 : 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color.withValues(alpha: 0.18),
            widget.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(widget.isHorizontal ? 8 : 12),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          widget.icon,
          color: widget.color,
          size: widget.isHorizontal ? 18 : 22,
        ),
      ),
    );

    final Widget actionCard = Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GlassCard(
        padding: widget.isHorizontal
            ? const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              )
            : const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
        margin: EdgeInsets.zero,
        borderRadius: 16,
        borderOpacity: isDark ? 0.12 : 0.08,
        shadowOpacity: 0,
        blurSigma: 8,
        child: SizedBox(
          height: widget.isHorizontal ? 40 : 108,
          child: widget.isHorizontal
              ? Row(
                  children: [
                    if (disableAnimations)
                      iconContainer
                    else
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: child,
                          );
                        },
                        child: iconContainer,
                      ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.label,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (disableAnimations)
                      iconContainer
                    else
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: child,
                          );
                        },
                        child: iconContainer,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: widget.label,
      child: disableAnimations
          ? GestureDetector(
              onTap: widget.onTap,
              child: actionCard,
            )
          : GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: actionCard,
              ),
            ),
    );
  }
}
