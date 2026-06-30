import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

@LazySingleton(as: LocationService)
class DriverLocationServiceImpl implements LocationService {
  /// Creates a [DriverLocationServiceImpl].
  DriverLocationServiceImpl();

  StreamSubscription<geo.Position>? _positionSubscription;
  final StreamController<Either<Failure, Coordinates>>
      _locationStreamController =
      StreamController<Either<Failure, Coordinates>>.broadcast();

  geo.Position? _lastSentPosition;
  DateTime? _lastSentTime;
  TripId? _activeTripId;

  @override
  bool get isTracking => _positionSubscription != null;

  @override
  Stream<Either<Failure, Coordinates>> get locationStream =>
      _locationStreamController.stream;

  @override
  Future<Either<Failure, Unit>> startTracking(
    TripId tripId, {
    required String notificationTitle,
    required String notificationText,
  }) async {
    // Already tracking this exact trip — nothing to do.
    if (_activeTripId == tripId && _positionSubscription != null) {
      return const Right(unit);
    }

    // If we were tracking a different trip, tear that down first.
    await stopTracking();
    _activeTripId = tripId;

    try {
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        final requested = await geo.Geolocator.requestPermission();
        if (requested == geo.LocationPermission.denied ||
            requested == geo.LocationPermission.deniedForever) {
          return const Left(LocationFailure(isPermissionDenied: true));
        }
      }
      if (permission == geo.LocationPermission.deniedForever) {
        return const Left(LocationFailure(isPermissionDenied: true));
      }

      final locationSettings = _resolveLocationSettings(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
      );

      _positionSubscription =
          geo.Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
        (position) => _onPosition(position, tripId),
        onError: (Object e) {
          _locationStreamController.add(
            Left(LocationFailure(message: e.toString())),
          );
        },
      );
      return const Right(unit);
    } catch (e) {
      return Left(LocationFailure(message: e.toString()));
    }
  }

  @override
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastSentPosition = null;
    _lastSentTime = null;
    _activeTripId = null;
  }

  void _onPosition(geo.Position position, TripId tripId) {
    final now = DateTime.now();
    if (!_shouldUpdate(position, now)) return;

    _lastSentPosition = position;
    _lastSentTime = now;
    _locationStreamController.add(
      Right(Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      )),
    );
  }

  bool _shouldUpdate(geo.Position position, DateTime now) {
    if (_lastSentPosition == null || _lastSentTime == null) {
      return true;
    }

    final distance = geo.Geolocator.distanceBetween(
      _lastSentPosition!.latitude,
      _lastSentPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    if (distance >= 20) return true;

    if (position.heading != 0 &&
        _lastSentPosition!.heading != 0 &&
        position.speed > 1) {
      final hDiff = (position.heading - _lastSentPosition!.heading).abs() % 360;
      final actualDiff = hDiff > 180 ? 360 - hDiff : hDiff;
      if (actualDiff >= 15) return true;
    }

    if (now.difference(_lastSentTime!) >= const Duration(minutes: 3)) {
      return true;
    }

    return false;
  }

  geo.LocationSettings _resolveLocationSettings({
    required String notificationTitle,
    required String notificationText,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationText: notificationText,
          notificationTitle: notificationTitle,
          enableWakeLock: true,
        ),
      );
    }
    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 10,
    );
  }

  @override
  @disposeMethod
  void dispose() {
    _positionSubscription?.cancel();
    _locationStreamController.close();
  }
}
