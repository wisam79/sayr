import 'package:sayr_core/sayr_core.dart';

/// DTO for Route from Supabase.
class RouteModel {
  const RouteModel({
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
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.departureTime,
    this.returnTime,
    this.daysOfWeek = const <String>[],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      title: json['title'] as String,
      startLocation: json['start_location'] as String,
      endLocation: json['end_location'] as String,
      price: Money((json['price'] as num).toInt()),
      capacity: (json['capacity'] as num).toInt(),
      availableSeats: (json['available_seats'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
      institutionId: json['institution_id'] != null
          ? InstitutionId(json['institution_id'] as String)
          : null,
      startLat: (json['start_lat'] as num?)?.toDouble(),
      startLng: (json['start_lng'] as num?)?.toDouble(),
      endLat: (json['end_lat'] as num?)?.toDouble(),
      endLng: (json['end_lng'] as num?)?.toDouble(),
      departureTime: json['departure_time'] as String?,
      returnTime: json['return_time'] as String?,
      daysOfWeek: (json['days_of_week'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );
  }

  final String id;
  final String driverId;
  final String title;
  final String startLocation;
  final String endLocation;
  final Money price;
  final int capacity;
  final int availableSeats;
  final bool isActive;
  final InstitutionId? institutionId;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? departureTime;
  final String? returnTime;
  final List<String> daysOfWeek;

  /// Convert to a domain entity.
  Route toEntity() => Route(
        id: RouteId(id),
        driverId: DriverId(driverId),
        title: title,
        startLocation: startLocation,
        endLocation: endLocation,
        price: price,
        capacity: capacity,
        availableSeats: availableSeats,
        isActive: isActive,
        institutionId: institutionId,
        startCoordinates: (startLat != null && startLng != null)
            ? Coordinates(latitude: startLat!, longitude: startLng!)
            : null,
        endCoordinates: (endLat != null && endLng != null)
            ? Coordinates(latitude: endLat!, longitude: endLng!)
            : null,
        departureTime: departureTime,
        returnTime: returnTime,
        daysOfWeek: daysOfWeek,
      );
}
