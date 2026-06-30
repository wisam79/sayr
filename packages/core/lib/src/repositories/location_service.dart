import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/src/failures/failure.dart';
import 'package:sayr_core/src/value_objects/coordinates.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

/// Abstract interface for live location tracking/streaming.
abstract class LocationService {
  /// Starts streaming the location of the active trip.
  Future<Either<Failure, Unit>> startTracking(
    TripId tripId, {
    required String notificationTitle,
    required String notificationText,
  });

  /// Stops streaming location.
  Future<void> stopTracking();

  /// Emits location updates, or location-related failures.
  Stream<Either<Failure, Coordinates>> get locationStream;

  /// Whether the service is currently active and streaming.
  bool get isTracking;

  /// Closes streams and cleans up resources.
  void dispose();
}
