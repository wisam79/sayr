import 'package:equatable/equatable.dart';

import '../enums/trip_status.dart';
import '../value_objects/coordinates.dart';
import '../value_objects/ids.dart';

/// A scheduled or in-progress trip on a route.
class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.status,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.lastLocation,
    this.routeStartLat,
    this.routeStartLng,
    this.routeEndLat,
    this.routeEndLng,
  });

  /// Unique trip ID.
  final TripId id;

  /// The route this trip belongs to.
  final RouteId routeId;

  /// The assigned driver.
  final DriverId driverId;

  /// Current trip status.
  final TripStatus status;

  /// Scheduled start time.
  final DateTime scheduledAt;

  /// Actual start time (when status became inTransit).
  final DateTime? startedAt;

  /// Actual end time (when status became completed/cancelled).
  final DateTime? endedAt;

  /// Last known location of the vehicle.
  final Coordinates? lastLocation;

  /// Route start latitude (cached for quick access).
  final double? routeStartLat;

  /// Route start longitude.
  final double? routeStartLng;

  /// Route end latitude.
  final double? routeEndLat;

  /// Route end longitude.
  final double? routeEndLng;

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

  @override
  List<Object?> get props => [
        id,
        routeId,
        driverId,
        status,
        scheduledAt,
        startedAt,
        endedAt,
        lastLocation,
        routeStartLat,
        routeStartLng,
        routeEndLat,
        routeEndLng,
      ];
}
