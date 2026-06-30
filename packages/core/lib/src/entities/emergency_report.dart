import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/value_objects/coordinates.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'emergency_report.freezed.dart';

/// An emergency report (SOS) from a participant in a trip.
@freezed
abstract class EmergencyReport with _$EmergencyReport {
  const factory EmergencyReport({
    required EmergencyReportId id,
    required UserId userId,
    required TripId tripId,
    required DateTime createdAt,
    Coordinates? location,
    DateTime? resolvedAt,
    String? notes,
  }) = _EmergencyReport;

  const EmergencyReport._();

  /// Whether the report is still active.
  bool get isActive => resolvedAt == null;
}
