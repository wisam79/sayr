import 'package:flutter/material.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Maps a [TripStatus] to its visual representation (color + icon).
extension TripStatusUi on TripStatus {
  /// Primary color for this status (used in chips, banners, etc.).
  Color get color {
    switch (this) {
      case TripStatus.scheduled:
        return Colors.orange;
      case TripStatus.driverWaiting:
        return Colors.blue;
      case TripStatus.inTransit:
        return AppColors.primary;
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.absent:
        return AppColors.error;
      case TripStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  /// Icon for this status.
  IconData get icon {
    switch (this) {
      case TripStatus.scheduled:
        return Icons.schedule;
      case TripStatus.driverWaiting:
        return Icons.hourglass_top;
      case TripStatus.inTransit:
        return Icons.directions_bus;
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.absent:
        return Icons.person_off;
      case TripStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// Shared status chip widget for [TripStatus].
///
/// Use in trip lists, trip detail headers, etc.
class TripStatusChip extends StatelessWidget {
  const TripStatusChip({super.key, required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Chip(
      avatar: Icon(status.icon, size: 16, color: color),
      label: Text(
        status.displayNameAr,
        style: TextStyle(color: color),
      ),
      backgroundColor: color.withAlpha(15),
      side: BorderSide.none,
    );
  }
}
