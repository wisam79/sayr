import 'package:flutter/material.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Maps a [TripStatus] to its visual representation (color + icon).
extension TripStatusUi on TripStatus {
  /// Primary color for this status (used in chips, banners, etc.).
  Color get color {
    switch (this) {
      case TripStatus.scheduled:
        return AppColors.statusScheduled;
      case TripStatus.driverWaiting:
        return AppColors.statusDriverWaiting;
      case TripStatus.inTransit:
        return AppColors.statusInTransit;
      case TripStatus.completed:
        return AppColors.statusCompleted;
      case TripStatus.absent:
        return AppColors.statusAbsent;
      case TripStatus.cancelled:
        return AppColors.statusCancelled;
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

  /// Localized display name from the current [AppLocalizations].
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case TripStatus.scheduled:
        return l10n.tripStatusScheduled;
      case TripStatus.driverWaiting:
        return l10n.tripStatusDriverWaiting;
      case TripStatus.inTransit:
        return l10n.tripStatusInTransit;
      case TripStatus.completed:
        return l10n.tripStatusCompleted;
      case TripStatus.absent:
        return l10n.tripStatusAbsent;
      case TripStatus.cancelled:
        return l10n.tripStatusCancelled;
    }
  }
}

/// Shared status chip widget for [TripStatus].
///
/// Use in trip lists, trip detail headers, etc.
class TripStatusChip extends StatelessWidget {
  /// Creates a [TripStatusChip] showing visual indicator for [status].
  const TripStatusChip({required this.status, super.key});

  /// The active [TripStatus] of the trip.
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = status.color;
    return Chip(
      avatar: Icon(status.icon, size: 16, color: color),
      label: Text(
        status.localizedName(l10n),
        style: TextStyle(color: color),
      ),
      backgroundColor: color.withAlpha(15),
      side: BorderSide.none,
    );
  }
}
