import 'package:flutter/material.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// A single location line showing an [icon], [color], and [label].
class LocationTile extends StatelessWidget {
  const LocationTile({required this.icon, required this.color, required this.label, super.key,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
