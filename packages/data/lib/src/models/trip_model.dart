import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

@freezed
abstract class TripModel with _$TripModel {
  const factory TripModel({
    required String id,
    @JsonKey(name: 'route_id') required String routeId,
    @JsonKey(name: 'driver_id') required String driverId,
    required String status,
    @JsonKey(name: 'scheduled_at') required DateTime scheduledAt,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'ended_at') DateTime? endedAt,
    @JsonKey(name: 'last_lat') double? lastLat,
    @JsonKey(name: 'last_lng') double? lastLng,
    @JsonKey(name: 'route_start_lat') double? routeStartLat,
    @JsonKey(name: 'route_start_lng') double? routeStartLng,
    @JsonKey(name: 'route_end_lat') double? routeEndLat,
    @JsonKey(name: 'route_end_lng') double? routeEndLng,
  }) = _TripModel;

  const TripModel._();

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);

  Trip toEntity() => Trip(
        id: TripId(id),
        routeId: RouteId(routeId),
        driverId: DriverId(driverId),
        status: TripStatus.fromString(status),
        scheduledAt: scheduledAt,
        startedAt: startedAt,
        endedAt: endedAt,
        lastLocation: (lastLat != null && lastLng != null)
            ? Coordinates(latitude: lastLat!, longitude: lastLng!)
            : null,
        routeStartLocation: (routeStartLat != null && routeStartLng != null)
            ? Coordinates(latitude: routeStartLat!, longitude: routeStartLng!)
            : null,
        routeEndLocation: (routeEndLat != null && routeEndLng != null)
            ? Coordinates(latitude: routeEndLat!, longitude: routeEndLng!)
            : null,
      );
}
