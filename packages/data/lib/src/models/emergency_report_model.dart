import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'emergency_report_model.freezed.dart';
part 'emergency_report_model.g.dart';

@freezed
abstract class EmergencyReportModel with _$EmergencyReportModel {
  const factory EmergencyReportModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'trip_id') required String tripId,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    String? notes,
  }) = _EmergencyReportModel;

  const EmergencyReportModel._();

  factory EmergencyReportModel.fromJson(Map<String, dynamic> json) =>
      _$EmergencyReportModelFromJson(json);

  EmergencyReport toEntity() => EmergencyReport(
        id: EmergencyReportId(id),
        userId: UserId(userId),
        tripId: TripId(tripId),
        location: Coordinates(latitude: latitude, longitude: longitude),
        createdAt: createdAt,
        resolvedAt: resolvedAt,
        notes: notes,
      );
}
