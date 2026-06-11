import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// A premium animated success dialog displayed upon successful license activation.
class SuccessSubscriptionDialog extends StatefulWidget {
  /// Creates a [SuccessSubscriptionDialog].
  const SuccessSubscriptionDialog({required this.onConfirm, super.key});

  /// Callback when the confirm button is pressed.
  final VoidCallback onConfirm;

  @override
  State<SuccessSubscriptionDialog> createState() =>
      _SuccessSubscriptionDialogState();
}

class _SuccessSubscriptionDialogState extends State<SuccessSubscriptionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    // Provide a subtle premium haptic tap upon success
    HapticFeedback.successNotification();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            ScaleTransition(
              scale: _checkAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: _AnimatedCheckmark(controller: _controller),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.licenseActivated,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.paymentSuccessSubscription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.goHome,
              onPressed: widget.onConfirm,
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCheckmark extends StatelessWidget {
  const _AnimatedCheckmark({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(40, 40),
          painter: _CheckmarkPainter(controller.value),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startX = size.width * 0.28;
    final startY = size.height * 0.52;
    final midX = size.width * 0.45;
    final midY = size.height * 0.68;
    final endX = size.width * 0.72;
    final endY = size.height * 0.36;

    if (progress < 0.4) {
      final p = progress / 0.4;
      path
        ..moveTo(startX, startY)
        ..lineTo(
          startX + (midX - startX) * p,
          startY + (midY - startY) * p,
        );
    } else {
      final p = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      path
        ..moveTo(startX, startY)
        ..lineTo(midX, midY)
        ..lineTo(
          midX + (endX - midX) * p,
          midY + (endY - midY) * p,
        );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
