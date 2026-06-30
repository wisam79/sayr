import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/trip_status.dart';
import 'package:sayr_core/src/value_objects/coordinates.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'trip.freezed.dart';

/// A scheduled or in-progress trip on a route.
@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required TripId id,
    required RouteId routeId,
    required DriverId driverId,
    required TripStatus status,
    required DateTime scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    Coordinates? lastLocation,
    Coordinates? routeStartLocation,
    Coordinates? routeEndLocation,
  }) = _Trip;

  const Trip._();

  /// Whether the trip is in a terminal state.
  bool get isCompleted => status == TripStatus.completed;

  /// Whether the trip is cancelled.
  bool get isCancelled => status == TripStatus.cancelled;

  /// Whether the trip is active (in progress or starting soon).
  bool get isActive => status.isActive;

  /// Whether the trip is in the future.
  bool get isUpcoming => scheduledAt.isAfter(clock.now());

  /// Trip duration so far (or total if completed).
  Duration? get duration {
    if (startedAt == null) return null;
    final end = endedAt ?? clock.now();
    return end.difference(startedAt!);
  }
}
