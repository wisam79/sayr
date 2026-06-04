import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart' as ll;

/// Geographic coordinates (latitude, longitude).
///
/// Valid range: lat ∈ [-90, 90], lng ∈ [-180, 180].
///
/// This is a thin wrapper over [ll.LatLng] that adds type-safety and validation.
/// All distance/bearing calculations use the [Distance] utility from `latlong2`.
class Coordinates extends Equatable {
  const Coordinates({
    required this.latitude,
    required this.longitude,
  });

  /// Latitude in degrees (-90 to 90)
  final double latitude;

  /// Longitude in degrees (-180 to 180)
  final double longitude;

  /// Convert to `latlong2` LatLng for map & math operations.
  ll.LatLng get toLatLng => ll.LatLng(latitude, longitude);

  /// Whether the coordinates are valid.
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !latitude.isNaN &&
        !longitude.isNaN &&
        !latitude.isInfinite &&
        !longitude.isInfinite;
  }

  /// Distance in meters to another coordinate.
  ///
  /// Uses the Haversine formula from `latlong2` package.
  double distanceToMeters(Coordinates other) {
    return const ll.Distance().as(
      ll.LengthUnit.Meter,
      toLatLng,
      other.toLatLng,
    );
  }

  /// Distance in kilometers to another coordinate.
  double distanceToKm(Coordinates other) {
    return const ll.Distance().as(
      ll.LengthUnit.Kilometer,
      toLatLng,
      other.toLatLng,
    );
  }

  /// Bearing to another coordinate in degrees (0 = North, 90 = East).
  double bearingTo(Coordinates other) {
    return const ll.Distance().bearing(toLatLng, other.toLatLng);
  }

  /// Midpoint between this and another coordinate.
  Coordinates midpoint(Coordinates other) {
    final lat1 = _deg2rad(latitude);
    final lat2 = _deg2rad(other.latitude);
    final lng1 = _deg2rad(longitude);
    final dLng = _deg2rad(other.longitude - longitude);

    final bx = math.cos(lat2) * math.cos(dLng);
    final by = math.cos(lat2) * math.sin(dLng);
    final lat3 = math.atan2(
      math.sin(lat1) + math.sin(lat2),
      math.sqrt((math.cos(lat1) + bx) * (math.cos(lat1) + bx) + by * by),
    );
    final lng3 =
        lng1 + math.atan2(by, math.cos(lat1) + bx);

    return Coordinates(
      latitude: _rad2deg(lat3),
      longitude: _rad2deg(lng3),
    );
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;
  static double _rad2deg(double r) => r * 180.0 / math.pi;

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => 'Coordinates($latitude, $longitude)';
}
