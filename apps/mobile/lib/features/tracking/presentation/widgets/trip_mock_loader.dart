import 'package:flutter/material.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Skeleton placeholder shown while the tracking stream connects.
class TripMockLoader extends StatelessWidget {
  const TripMockLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.grey[200]),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _greyBox(radius: 6),
                      const Spacer(),
                      _greyBox(width: 50, radius: 6),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _skeletonRow(Icons.circle, AppColors.primary),
                  const SizedBox(height: 12),
                  _skeletonRow(Icons.location_on, AppColors.error),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  _skeletonDriver(),
                  const SizedBox(height: AppSpacing.lg),
                  _skeletonButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _greyBox({double width = 80, double height = 24, double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _skeletonRow(IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _greyBox()),
      ],
    );
  }

  Widget _skeletonDriver() {
    return Row(
      children: [
        const CircleAvatar(radius: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _greyBox(width: 120),
              const SizedBox(height: 4),
              _greyBox(height: 12),
            ],
          ),
        ),
        _greyBox(width: 40, radius: 6),
      ],
    );
  }

  Widget _skeletonButtons() {
    return Row(
      children: [
        Expanded(
          child: _greyBox(width: double.infinity, height: 48, radius: 12),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _greyBox(width: double.infinity, height: 48, radius: 12),
        ),
      ],
    );
  }
}
