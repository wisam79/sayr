import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/trip_status.dart';
import '../value_objects/coordinates.dart';
import '../value_objects/ids.dart';
import '../utils/json_converters.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

/// A scheduled or in-progress trip on a route.
@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    @JsonKey(fromJson: tripIdFromJson, toJson: tripIdToJson) required TripId id,
    @JsonKey(fromJson: routeIdFromJson, toJson: routeIdToJson)
    required RouteId routeId,
    @JsonKey(fromJson: driverIdFromJson, toJson: driverIdToJson)
    required DriverId driverId,
    @JsonKey(fromJson: tripStatusFromJson, toJson: tripStatusToJson)
    required TripStatus status,
    required DateTime scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    @JsonKey(
        fromJson: nullableCoordinatesFromJson,
        toJson: nullableCoordinatesToJson)
    Coordinates? lastLocation,
    @JsonKey(
        fromJson: nullableCoordinatesFromJson,
        toJson: nullableCoordinatesToJson)
    Coordinates? routeStartLocation,
    @JsonKey(
        fromJson: nullableCoordinatesFromJson,
        toJson: nullableCoordinatesToJson)
    Coordinates? routeEndLocation,
  }) = _Trip;

  const Trip._();

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// Expose routeStartLat for backward compatibility.
  double? get routeStartLat => routeStartLocation?.latitude;

  /// Expose routeStartLng for backward compatibility.
  double? get routeStartLng => routeStartLocation?.longitude;

  /// Expose routeEndLat for backward compatibility.
  double? get routeEndLat => routeEndLocation?.latitude;

  /// Expose routeEndLng for backward compatibility.
  double? get routeEndLng => routeEndLocation?.longitude;

  /// Whether the trip is in a terminal state.
  bool get isCompleted => status == TripStatus.completed;

  /// Whether the trip is cancelled.
  bool get isCancelled => status == TripStatus.cancelled;

  /// Whether the trip is active (in progress or starting soon).
  bool get isActive => status.isActive;

  /// Whether the trip is in the future.
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());

  /// Trip duration so far (or total if completed).
  Duration? get duration {
    if (startedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
}
