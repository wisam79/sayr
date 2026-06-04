import 'package:equatable/equatable.dart';

import '../value_objects/coordinates.dart';
import '../value_objects/ids.dart';
import '../value_objects/money.dart';

/// A bus route from start location to end location.
class Route extends Equatable {
  const Route({
    required this.id,
    required this.driverId,
    required this.title,
    required this.startLocation,
    required this.endLocation,
    required this.price,
    required this.capacity,
    required this.availableSeats,
    required this.isActive,
    this.institutionId,
    this.startCoordinates,
    this.endCoordinates,
    this.departureTime,
    this.returnTime,
    this.daysOfWeek = const <String>[],
  });

  /// Unique route ID.
  final RouteId id;

  /// Assigned driver.
  final DriverId driverId;

  /// Display title (e.g., "جامعة بغداد - الكرادة").
  final String title;

  /// Start location name (e.g., "جامعة بغداد").
  final String startLocation;

  /// End location name (e.g., "الكرادة").
  final String endLocation;

  /// Subscription price.
  final Money price;

  /// Total vehicle capacity.
  final int capacity;

  /// Currently available seats.
  final int availableSeats;

  /// Whether the route is active (visible to students).
  final bool isActive;

  /// Institution (university) the route serves.
  final InstitutionId? institutionId;

  /// Start location coordinates.
  final Coordinates? startCoordinates;

  /// End location coordinates.
  final Coordinates? endCoordinates;

  /// Daily departure time (HH:mm format).
  final String? departureTime;

  /// Daily return time (HH:mm format).
  final String? returnTime;

  /// Days of week when the route operates (e.g., ["sun", "mon", ...]).
  final List<String> daysOfWeek;

  /// Whether the route has available seats.
  bool get hasSeats => availableSeats > 0;

  /// Seat occupancy ratio (0.0 to 1.0).
  double get occupancyRatio {
    if (capacity == 0) return 0;
    return (capacity - availableSeats) / capacity;
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        title,
        startLocation,
        endLocation,
        price,
        capacity,
        availableSeats,
        isActive,
        institutionId,
        startCoordinates,
        endCoordinates,
        departureTime,
        returnTime,
        daysOfWeek,
      ];
}
