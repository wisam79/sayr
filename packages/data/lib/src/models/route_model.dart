import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'route_model.freezed.dart';
part 'route_model.g.dart';

/// DTO for Route from Supabase (freezed version).
@freezed
abstract class RouteModel with _$RouteModel {
  const factory RouteModel({
    required String id,
    @JsonKey(name: 'driver_id') required String driverId,
    required String title,
    @JsonKey(name: 'start_location') required String startLocation,
    @JsonKey(name: 'end_location') required String endLocation,
    required int price,
    required int capacity,
    @JsonKey(name: 'available_seats') required int availableSeats,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'institution_id') String? institutionId,
    @JsonKey(name: 'start_lat') double? startLat,
    @JsonKey(name: 'start_lng') double? startLng,
    @JsonKey(name: 'end_lat') double? endLat,
    @JsonKey(name: 'end_lng') double? endLng,
    @JsonKey(name: 'departure_time') String? departureTime,
    @JsonKey(name: 'return_time') String? returnTime,
    @JsonKey(name: 'days_of_week') @Default(<String>[]) List<String> daysOfWeek,
  }) = _RouteModel;

  const RouteModel._();

  factory RouteModel.fromJson(Map<String, dynamic> json) =>
      _$RouteModelFromJson(json);

  /// Convert to a domain entity.
  Route toEntity() => Route(
        id: RouteId(id),
        driverId: DriverId(driverId),
        title: title,
        startLocation: startLocation,
        endLocation: endLocation,
        price: Money(price),
        capacity: capacity,
        availableSeats: availableSeats,
        isActive: isActive,
        institutionId:
            institutionId != null ? InstitutionId(institutionId!) : null,
        startCoordinates: (startLat != null && startLng != null)
            ? Coordinates(latitude: startLat!, longitude: startLng!)
            : null,
        endCoordinates: (endLat != null && endLng != null)
            ? Coordinates(latitude: endLat!, longitude: endLng!)
            : null,
        departureTime: departureTime,
        returnTime: returnTime,
        daysOfWeek: daysOfWeek,
      );
}
