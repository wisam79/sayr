import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';

/// Owns the driver's live GPS stream independently of any page widget.
///
/// Previously the position subscription lived inside the driver controls page,
/// which meant tracking stopped the moment the driver left the page (even though
/// the Android foreground-service notification promised "tracking in the
/// background"). This service decouples the subscription's lifetime from the
/// page: it is started when a trip goes active ([startTracking]) and stopped
/// when the trip ends ([stopTracking]), so the geolocator foreground service
/// keeps streaming for as long as the trip requires.
///
/// The service does not talk to the network itself; it forwards each accepted
/// position to the supplied [TrackingBloc] via [TrackingUpdateLocation], which
/// is where the remote update + offline-queue fallback already live.
@LazySingleton()
class DriverLocationService {
  /// Creates a [DriverLocationService].
  DriverLocationService();

  StreamSubscription<geo.Position>? _positionSubscription;
  geo.Position? _lastSentPosition;
  DateTime? _lastSentTime;
  TripId? _activeTripId;

  /// Whether the service is currently streaming the driver's position.
  bool get isTracking => _positionSubscription != null;

  /// Begins streaming the driver's position for [tripId], forwarding updates to
  /// [trackingBloc]. Idempotent: calling it again while already tracking the
  /// same trip is a no-op. Throws [Exception] if location permission is denied
  /// so the caller can surface a typed error to the user.
  Future<void> startTracking({
    required TripId tripId,
    required TrackingBloc trackingBloc,
  }) async {
    // Already tracking this exact trip — nothing to do.
    if (_activeTripId == tripId && _positionSubscription != null) return;

    // If we were tracking a different trip, tear that down first.
    await stopTracking();
    _activeTripId = tripId;

    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      final requested = await geo.Geolocator.requestPermission();
      if (requested == geo.LocationPermission.denied ||
          requested == geo.LocationPermission.deniedForever) {
        throw const DriverLocationPermissionDenied();
      }
    }
    if (permission == geo.LocationPermission.deniedForever) {
      throw const DriverLocationPermissionDenied();
    }

    final locationSettings = _resolveLocationSettings();

    _positionSubscription =
        geo.Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
      (position) => _onPosition(position, tripId, trackingBloc),
    );
  }

  /// Stops streaming and releases the position subscription. Safe to call when
  /// not tracking.
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastSentPosition = null;
    _lastSentTime = null;
    _activeTripId = null;
  }

  void _onPosition(
    geo.Position position,
    TripId tripId,
    TrackingBloc trackingBloc,
  ) {
    if (trackingBloc.isClosed) {
      // The bloc is gone — stop streaming to avoid orphaned updates.
      unawaited(stopTracking());
      return;
    }

    final now = DateTime.now();
    if (!_shouldUpdate(position, now)) return;

    _lastSentPosition = position;
    _lastSentTime = now;
    trackingBloc.add(
      TrackingUpdateLocation(
        tripId: tripId,
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }

  /// Decides whether a new [position] is meaningful enough to forward, using
  /// the same throttling rules the page used: move ≥20m, heading change ≥15°,
  /// or a 3-minute heartbeat.
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

    // Only evaluate heading change when actually moving (>1 m/s) so static GPS
    // jitter does not trigger a flood of updates.
    if (position.heading != 0 &&
        _lastSentPosition!.heading != 0 &&
        position.speed > 1) {
      final hDiff =
          (position.heading - _lastSentPosition!.heading).abs() % 360;
      final actualDiff = hDiff > 180 ? 360 - hDiff : hDiff;
      if (actualDiff >= 15) return true;
    }

    // Heartbeat: keep the backend warm even when stationary.
    if (now.difference(_lastSentTime!) >= const Duration(minutes: 3)) {
      return true;
    }

    return false;
  }

  geo.LocationSettings _resolveLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationText: "جاري مشاركة موقع الحافلة مع الطلاب",
          notificationTitle: "سير - تتبع الرحلة النشطة",
          enableWakeLock: true,
        ),
      );
    }
    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 10,
    );
  }
}

/// Thrown when the driver has not granted location permission, so callers can
/// map it to a user-facing message rather than a generic failure.
class DriverLocationPermissionDenied implements Exception {
  /// Creates a [DriverLocationPermissionDenied].
  const DriverLocationPermissionDenied();
}
