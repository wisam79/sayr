import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';

/// A premium card used to greet users (students/drivers) with a corporate forest green theme
/// and elegant background geometric patterns.
class GreetingCard extends StatelessWidget {
  /// Creates a [GreetingCard].
  const GreetingCard({
    required this.title,
    required this.subtitle,
    required this.avatarWidget,
    required this.badgeWidget,
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

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
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
                decoration: const BoxDecoration(
                  color: Color(0x0AFFFFFF), // white with ~0.04 opacity
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -80,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Color(0x05FFFFFF), // white with ~0.02 opacity
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: Color(0x08FFFFFF), // white with ~0.03 opacity
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Baghdad University gate and landmarks (opacity 0.03)
            const Positioned.fill(
              child: CustomPaint(
                painter: _UniversityGatePainter(
                  color: Color(0x0BFFFFFF), // Very subtle white line art
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  avatarWidget,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Color(0xD9FFFFFF), // 85% opacity
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        badgeWidget,
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
      ..strokeWidth = 1.0;

    final bottom = size.height;

    // 1. Draw Gropius Arch (Iconic arch of the University of Baghdad)
    final archCenter = size.width * 0.72;
    final archWidth = size.width * 0.22;
    final archHeight = size.height * 0.8;

    final path = Path()
      ..moveTo(archCenter - archWidth / 2, bottom)
      ..quadraticBezierTo(
        archCenter,
        bottom - archHeight * 1.8,
        archCenter + archWidth / 2,
        bottom,
      )
      // Inner arch
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
