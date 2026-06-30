import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/license_status.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/license_code.dart';

part 'license.freezed.dart';

/// A license code that grants a student access to a route.
@freezed
abstract class License with _$License {
  const factory License({
    required LicenseId id,
    required LicenseBatchId batchId,
    required RouteId routeId,
    required LicenseCode code,
    required LicenseStatus status,
    required int validDays,
    required DateTime createdAt,
    UserId? usedBy,
    DateTime? usedAt,
  }) = _License;

  const License._();

  /// Whether this license can be activated.
  bool get isActivatable => status.isActivatable;
}

/// A batch of licenses created by an admin.
@freezed
abstract class LicenseBatch with _$LicenseBatch {
  const factory LicenseBatch({
    required LicenseBatchId id,
    required UserId createdBy,
    required RouteId routeId,
    required String batchName,
    required int quantity,
    required int price,
    required int validDays,
    required DateTime createdAt,
  }) = _LicenseBatch;
}
