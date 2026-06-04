import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/coordinates.dart';
import '../value_objects/ids.dart';
import '../utils/json_converters.dart';

part 'emergency_report.freezed.dart';
part 'emergency_report.g.dart';

/// An emergency report (SOS) from a participant in a trip.
@freezed
abstract class EmergencyReport with _$EmergencyReport {
  const factory EmergencyReport({
    @JsonKey(
        fromJson: emergencyReportIdFromJson, toJson: emergencyReportIdToJson)
    required EmergencyReportId id,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId userId,
    @JsonKey(fromJson: tripIdFromJson, toJson: tripIdToJson)
    required TripId tripId,
    @JsonKey(fromJson: coordinatesFromJson, toJson: coordinatesToJson)
    required Coordinates location,
    required DateTime createdAt,
    DateTime? resolvedAt,
    String? notes,
  }) = _EmergencyReport;

  const EmergencyReport._();

  factory EmergencyReport.fromJson(Map<String, dynamic> json) =>
      _$EmergencyReportFromJson(json);

  /// Whether the report is still active.
  bool get isActive => resolvedAt == null;
}
