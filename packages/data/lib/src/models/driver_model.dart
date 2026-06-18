import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'driver_model.freezed.dart';
part 'driver_model.g.dart';

/// DTO for Driver rows coming from Supabase.
///
/// Mirrors the column names exposed by the `drivers` view so a raw row can be
/// parsed directly via [DriverModel.fromJson], then converted to the [Driver]
/// domain entity via [toEntity]. This replaces the hand-written
/// `_driverFromDb` mapper that previously lived in the repository.
@freezed
abstract class DriverModel with _$DriverModel {
  const factory DriverModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'vehicle_model') required String vehicleModel,
    @JsonKey(name: 'vehicle_plate') required String vehiclePlate,
    required int capacity,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @Default(0.0) double rating,
  }) = _DriverModel;

  const DriverModel._();

  factory DriverModel.fromJson(Map<String, dynamic> json) =>
      _$DriverModelFromJson(json);

  /// Convert to a domain entity.
  Driver toEntity() => Driver(
        id: DriverId(id),
        userId: UserId(userId),
        vehicleModel: vehicleModel,
        vehiclePlate: vehiclePlate,
        capacity: capacity,
        isVerified: isVerified,
        rating: rating,
      );
}
