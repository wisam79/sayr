import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart' as ll;

/// Geographic coordinates (latitude, longitude).
///
/// Valid range: lat ∈ [-90, 90], lng ∈ [-180, 180].
///
/// This is a thin wrapper over [ll.LatLng] that adds type-safety and validation.
/// All distance/bearing calculations use the [ll.Distance] utility from `latlong2`.
class Coordinates extends Equatable {
  /// Creates [Coordinates] with validation.
  ///
  /// Throws [ArgumentError] if latitude or longitude are out of range,
  /// NaN, or infinite.
  factory Coordinates({
    required double latitude,
    required double longitude,
  }) {
    if (latitude.isNaN ||
        latitude.isInfinite ||
        latitude < -90 ||
        latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Must be between -90 and 90 (inclusive) and finite',
      );
    }
    if (longitude.isNaN ||
        longitude.isInfinite ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be between -180 and 180 (inclusive) and finite',
      );
    }
    return Coordinates._(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Internal const constructor (skips validation).
  ///
  /// Used by JSON deserialization and tests where values are known-good.
  const Coordinates._({
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
  ///
  /// Always returns `true` for instances created via the public factory.
  /// Retained for backward compatibility with code that checks validity.
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

  /// Approximate midpoint between this and another coordinate.
  ///
  /// Uses arithmetic mean (not geodesic). Accurate for short distances
  /// (<50 km) typical of intra-city university routes in Iraq.
  /// Error at equator for 50 km: ~0.004%. For full geodesic midpoint
  /// use `latlong2.Path.center()`.
  Coordinates midpoint(Coordinates other) {
    return Coordinates._(
      latitude: (latitude + other.latitude) / 2,
      longitude: (longitude + other.longitude) / 2,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => 'Coordinates($latitude, $longitude)';
}
