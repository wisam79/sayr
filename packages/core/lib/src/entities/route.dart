import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/coordinates.dart';
import '../value_objects/ids.dart';
import '../value_objects/money.dart';
import '../utils/json_converters.dart';

part 'route.freezed.dart';
part 'route.g.dart';

/// A bus route from start location to end location.
@freezed
abstract class Route with _$Route {
  const factory Route({
    @JsonKey(fromJson: routeIdFromJson, toJson: routeIdToJson)
    required RouteId id,
    @JsonKey(fromJson: driverIdFromJson, toJson: driverIdToJson)
    required DriverId driverId,
    required String title,
    required String startLocation,
    required String endLocation,
    @JsonKey(fromJson: moneyFromJson, toJson: moneyToJson) required Money price,
    required int capacity,
    required int availableSeats,
    required bool isActive,
    @JsonKey(
        fromJson: nullableInstitutionIdFromJson,
        toJson: nullableInstitutionIdToJson)
    InstitutionId? institutionId,
    @JsonKey(
        fromJson: nullableCoordinatesFromJson,
        toJson: nullableCoordinatesToJson)
    Coordinates? startCoordinates,
    @JsonKey(
        fromJson: nullableCoordinatesFromJson,
        toJson: nullableCoordinatesToJson)
    Coordinates? endCoordinates,
    String? departureTime,
    String? returnTime,
    @Default(<String>[]) List<String> daysOfWeek,
  }) = _Route;

  const Route._();

  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);

  /// Whether the route has available seats.
  bool get hasSeats => availableSeats > 0;

  /// Seat occupancy ratio (0.0 to 1.0).
  double get occupancyRatio {
    if (capacity == 0) return 0;
    return (capacity - availableSeats) / capacity;
  }
}
