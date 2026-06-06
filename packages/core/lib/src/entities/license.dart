import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/license_status.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/license_code.dart';

part 'license.freezed.dart';
part 'license.g.dart';

/// A license code that grants a student access to a route.
@freezed
abstract class License with _$License {
  const factory License({
    @JsonKey(fromJson: licenseIdFromJson, toJson: licenseIdToJson)
    required LicenseId id,
    @JsonKey(fromJson: licenseBatchIdFromJson, toJson: licenseBatchIdToJson)
    required LicenseBatchId batchId,
    @JsonKey(fromJson: routeIdFromJson, toJson: routeIdToJson)
    required RouteId routeId,
    @JsonKey(fromJson: licenseCodeFromJson, toJson: licenseCodeToJson)
    required LicenseCode code,
    @JsonKey(fromJson: licenseStatusFromJson, toJson: licenseStatusToJson)
    required LicenseStatus status,
    required int validDays,
    required DateTime createdAt,
    @JsonKey(fromJson: nullableUserIdFromJson, toJson: nullableUserIdToJson)
    UserId? usedBy,
    DateTime? usedAt,
  }) = _License;

  const License._();

  factory License.fromJson(Map<String, dynamic> json) =>
      _$LicenseFromJson(json);

  /// Whether this license can be activated.
  bool get isActivatable => status.isActivatable;
}

/// A batch of licenses created by an admin.
@freezed
abstract class LicenseBatch with _$LicenseBatch {
  const factory LicenseBatch({
    @JsonKey(fromJson: licenseBatchIdFromJson, toJson: licenseBatchIdToJson)
    required LicenseBatchId id,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId createdBy,
    @JsonKey(fromJson: routeIdFromJson, toJson: routeIdToJson)
    required RouteId routeId,
    required String batchName,
    required int quantity,
    required int price,
    required int validDays,
    required DateTime createdAt,
  }) = _LicenseBatch;

  factory LicenseBatch.fromJson(Map<String, dynamic> json) =>
      _$LicenseBatchFromJson(json);
}
