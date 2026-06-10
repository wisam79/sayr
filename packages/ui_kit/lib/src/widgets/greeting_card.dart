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
