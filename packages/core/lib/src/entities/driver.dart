import 'package:equatable/equatable.dart';

import '../value_objects/ids.dart';

/// A driver profile with vehicle information.
class Driver extends Equatable {
  const Driver({
    required this.id,
    required this.userId,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.capacity,
    this.isVerified = false,
    this.rating = 0,
  });

  /// Driver record ID.
  final DriverId id;

  /// Associated user ID.
  final UserId userId;

  /// Vehicle model (e.g., "Toyota Coaster").
  final String vehicleModel;

  /// License plate number.
  final String vehiclePlate;

  /// Vehicle passenger capacity.
  final int capacity;

  /// Whether the driver is verified by admin.
  final bool isVerified;

  /// Average rating (0-5).
  final double rating;

  @override
  List<Object?> get props => [
        id,
        userId,
        vehicleModel,
        vehiclePlate,
        capacity,
        isVerified,
        rating,
      ];
}
