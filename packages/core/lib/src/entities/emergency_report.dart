import 'package:equatable/equatable.dart';

import '../value_objects/coordinates.dart';
import '../value_objects/ids.dart';

/// An emergency report (SOS) from a participant in a trip.
class EmergencyReport extends Equatable {
  const EmergencyReport({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.location,
    required this.createdAt,
    this.resolvedAt,
    this.notes,
  });

  /// Unique report ID.
  final EmergencyReportId id;

  /// The user who reported the emergency.
  final UserId userId;

  /// The trip during which the emergency occurred.
  final TripId tripId;

  /// Location at the time of the report.
  final Coordinates location;

  /// When the report was created.
  final DateTime createdAt;

  /// When the report was resolved.
  final DateTime? resolvedAt;

  /// Admin notes.
  final String? notes;

  /// Whether the report is still active.
  bool get isActive => resolvedAt == null;

  @override
  List<Object?> get props => [
        id,
        userId,
        tripId,
        location,
        createdAt,
        resolvedAt,
        notes,
      ];
}
