import 'package:flutter/material.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color.withValues(alpha: 0.18),
            widget.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 22,
        ),
      ),
    );

    final Widget actionCard = Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        margin: EdgeInsets.zero,
        borderRadius: 16,
        color: widget.color.withValues(alpha: isDark ? 0.06 : 0.03),
        borderOpacity: isDark ? 0.12 : 0.08,
        shadowOpacity: 0,
        blurSigma: 8,
        child: SizedBox(
          height: 108,
          child: Column(
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
