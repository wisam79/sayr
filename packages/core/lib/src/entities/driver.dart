import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'driver.freezed.dart';
part 'driver.g.dart';

/// A driver profile with vehicle information.
@freezed
abstract class Driver with _$Driver {
  const factory Driver({
    @JsonKey(fromJson: driverIdFromJson, toJson: driverIdToJson)
    required DriverId id,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId userId,
    required String vehicleModel,
    required String vehiclePlate,
    required int capacity,
    @Default(false) bool isVerified,
    @Default(0.0) double rating,
  }) = _Driver;

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
}
