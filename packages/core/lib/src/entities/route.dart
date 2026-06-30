import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/value_objects/coordinates.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/money.dart';

part 'route.freezed.dart';

/// A bus route from start location to end location.
@freezed
abstract class Route with _$Route {
  const factory Route({
    required RouteId id,
    required DriverId driverId,
    required String title,
    required String startLocation,
    required String endLocation,
    required Money price,
    required int capacity,
    required int availableSeats,
    required bool isActive,
    InstitutionId? institutionId,
    Coordinates? startCoordinates,
    Coordinates? endCoordinates,

    /// Departure time in 24-hour "HH:mm" format (e.g. "08:30").
    /// Represented as a String for seamless JSON and Database serialization.
    String? departureTime,

    /// Return time in 24-hour "HH:mm" format (e.g. "14:30").
    /// Represented as a String for seamless JSON and Database serialization.
    String? returnTime,
    @Default(<String>[]) List<String> daysOfWeek,
    String? geometry,
  }) = _Route;

  const Route._();

  /// Whether the route has available seats.
  bool get hasSeats => availableSeats > 0;

  /// Seat occupancy ratio (0.0 to 1.0).
  double get occupancyRatio {
    if (capacity == 0) return 0;
    return (capacity - availableSeats) / capacity;
  }
}
