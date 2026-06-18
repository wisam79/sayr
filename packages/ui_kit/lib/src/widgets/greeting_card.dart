import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A premium card used to greet users (students/drivers) with a corporate forest green theme,
/// elegant background geometric patterns, and shimmer sweep entrance animation.
class GreetingCard extends StatefulWidget {
  /// Creates a [GreetingCard].
  const GreetingCard({
    required this.title,
    required this.subtitle,
    required this.avatarWidget,
    required this.badgeWidget,
    this.isCompact = false,
    super.key,
  });

  /// The greeting/title text.
  final String title;

  /// The optional subtitle text.
  final String? subtitle;

  /// Widget to display the user avatar/initials.
  final Widget avatarWidget;

  /// Badge/role widget to display below the user name.
  final Widget badgeWidget;

  /// Whether to render a compact version of the card with reduced padding and font sizes.
  final bool isCompact;

  @override
  State<GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<GreetingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _shimmerController.stop();
    } else if (!_shimmerController.isAnimating &&
        _shimmerController.value < 1.0) {
      _shimmerController.forward();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = widget.subtitle != null && widget.subtitle!.isNotEmpty;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B), // Dark slate
            Color(0xFF0F172A), // Deep charcoal
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background patterns
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            // Baghdad University gate and landmarks (opacity increased to 0.07/Color(0x12FFFFFF))
            const Positioned.fill(
              child: CustomPaint(
                painter: _UniversityGatePainter(
                  color: Color(
                    0x12FFFFFF,
                  ), // Opacity increased from 0x0BFFFFFF to 0x12FFFFFF
                ),
              ),
            ),
            // Shimmer Overlay
            if (!disableAnimations)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        final shimmerPosition = _shimmerAnimation.value;
                        return LinearGradient(
                          begin: Alignment(-1.0 + 2.0 * shimmerPosition, -0.3),
                          end: Alignment(-0.5 + 2.0 * shimmerPosition, 0.3),
                          colors: const [
                            Color(0x00FFFFFF),
                            Color(0x1AFFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Container(color: Colors.white),
                    );
                  },
                ),
              ),
            // Card Content
            Padding(
              padding: EdgeInsets.all(
                widget.isCompact ? AppSpacing.md : AppSpacing.xl,
              ),
              child: Row(
                children: [
                  widget.avatarWidget,
                  SizedBox(
                    width: widget.isCompact ? AppSpacing.sm : AppSpacing.md,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.isCompact ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              color: Color(0xD9FFFFFF), // 85% opacity
                              fontSize: 14,
                            ),
                          ),
                        ],
                        SizedBox(
                          height: widget.isCompact ? AppSpacing.xs : 8,
                        ),
                        widget.badgeWidget,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom painter to draw a minimalist line art representation
/// of Iraqi university landmarks.
class _UniversityGatePainter extends CustomPainter {
  const _UniversityGatePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final bottom = size.height;

    // 1. Draw a minimalist arch (Baghdad University main gate) on the right
    final archCenter = size.width * 0.78;
    final archWidth = size.width * 0.16;
    final archHeight = size.height * 0.65;

    path
      // Left pillar base
      ..moveTo(archCenter - archWidth / 2, bottom)
      ..lineTo(archCenter - archWidth / 2, bottom - archHeight * 0.45)
      // Right pillar base
      ..moveTo(archCenter + archWidth / 2, bottom)
      ..lineTo(archCenter + archWidth / 2, bottom - archHeight * 0.45)
      // Top parabolic arch curve
      ..moveTo(archCenter - archWidth / 2, bottom - archHeight * 0.45)
      ..quadraticBezierTo(
        archCenter - archWidth * 0.4,
        bottom - archHeight * 0.95,
        archCenter,
        bottom - archHeight,
      )
      ..quadraticBezierTo(
        archCenter + archWidth * 0.4,
        bottom - archHeight * 0.95,
        archCenter + archWidth / 2,
        bottom - archHeight * 0.45,
      )
      // Parabolic inner arch curve
      ..moveTo(archCenter - archWidth * 0.35, bottom)
      ..quadraticBezierTo(
        archCenter,
        bottom - archHeight * 1.3,
        archCenter + archWidth * 0.35,
        bottom,
      );

    // 2. Draw a university dome in the middle
    final domeCenter = size.width * 0.45;
    final domeRadius = size.width * 0.10;
    path
      ..moveTo(domeCenter - domeRadius, bottom)
      ..quadraticBezierTo(
        domeCenter,
        bottom - domeRadius * 1.6,
        domeCenter + domeRadius,
        bottom,
      )
      // Dome top needle
      ..moveTo(domeCenter, bottom - domeRadius * 0.85)
      ..lineTo(domeCenter, bottom - domeRadius * 1.25);

    // 3. Draw a clocktower on the left
    final towerLeft = size.width * 0.18;
    final towerWidth = size.width * 0.08;
    final towerHeight = size.height * 0.75;

    path
      // Tower rect outline
      ..addRect(
        Rect.fromLTWH(
          towerLeft,
          bottom - towerHeight,
          towerWidth,
          towerHeight,
        ),
      )
      // Tower roof triangle
      ..moveTo(towerLeft, bottom - towerHeight)
      ..lineTo(
        towerLeft + towerWidth / 2,
        bottom - towerHeight - towerWidth * 0.55,
      )
      ..lineTo(towerLeft + towerWidth, bottom - towerHeight)
      // Clock outline
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            towerLeft + towerWidth / 2,
            bottom - towerHeight + towerWidth * 0.8,
          ),
          radius: towerWidth * 0.22,
        ),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
