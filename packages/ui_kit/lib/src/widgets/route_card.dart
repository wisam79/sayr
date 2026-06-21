import 'package:flutter/material.dart';

import 'package:sayr_ui_kit/src/theme/app_colors.dart';
import 'package:sayr_ui_kit/src/theme/app_spacing.dart';
import 'package:sayr_ui_kit/src/widgets/glass_card.dart';

/// A card displaying bus route details.
class RouteCard extends StatelessWidget {
  /// Creates a [RouteCard].
  const RouteCard({
    required this.title,
    required this.startLocation,
    required this.endLocation,
    required this.availableSeats,
    required this.capacity,
    required this.formattedPrice,
    required this.hasSeats,
    required this.availableLabel,
    required this.completedLabel,
    super.key,
    this.onTap,
  });

  /// The title of the route.
  final String title;

  /// The start location name.
  final String startLocation;

  /// The end location name.
  final String endLocation;

  /// The number of available seats.
  final int availableSeats;

  /// The total capacity of the route.
  final int capacity;

  /// The formatted price of the route.
  final String formattedPrice;

  /// Whether the route has seats available.
  final bool hasSeats;

  /// The localized label for available seats.
  final String availableLabel;

  /// The localized label for a full route.
  final String completedLabel;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (hasSeats)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                  child: Text(
                    availableLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                  child: Text(
                    completedLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.radio_button_checked,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  startLocation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 7),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.border,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.flag,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  endLocation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_seat,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$availableSeats/$capacity',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Text(
                formattedPrice,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
