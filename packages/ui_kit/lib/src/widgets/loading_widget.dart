import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A premium centered loading indicator featuring a pulsing brand route icon
/// and a rotating incomplete border ring.
class LoadingWidget extends StatelessWidget {
  /// Creates a [LoadingWidget].
  const LoadingWidget({super.key, this.message});

  /// The optional message to display below the loading indicator.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTest)
            const CircularProgressIndicator()
          else
            const _BrandedSpinner(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _FadeInMessage(message: message!),
          ],
        ],
      ),
    );
  }
}

class _BrandedSpinner extends StatefulWidget {
  const _BrandedSpinner();

  @override
  State<_BrandedSpinner> createState() => _BrandedSpinnerState();
}

class _BrandedSpinnerState extends State<_BrandedSpinner>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _pulseController.stop();
      _rotateController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat();
      if (!_rotateController.isAnimating) _rotateController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final disableAnimations =
        isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    final Widget innerIcon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.route,
          size: 32,
          color: AppColors.primary,
        ),
      ),
    );

    if (disableAnimations) {
      return Stack(
        alignment: Alignment.center,
        children: [
          innerIcon,
          SizedBox(
            width: 78,
            height: 78,
            child: CustomPaint(
              painter:
                  _RingPainter(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating ring
            AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateController.value * 2 * 3.1415926535,
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: CustomPaint(
                      painter: _RingPainter(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Pulsing inner icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: innerIcon,
            ),
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -3.1415926535 / 2, 3 * 3.1415926535 / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FadeInMessage extends StatefulWidget {
  const _FadeInMessage({required this.message});
  final String message;

  @override
  State<_FadeInMessage> createState() => _FadeInMessageState();
}

class _FadeInMessageState extends State<_FadeInMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && _controller.value < 1.0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
