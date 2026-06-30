import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/license_status.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/money.dart';

part 'license_preview.freezed.dart';

/// Pre-activation preview details of a license code.
@freezed
abstract class LicensePreview with _$LicensePreview {
  const factory LicensePreview({
    required LicenseId licenseId,
    required RouteId routeId,
    required String routeTitle,
    required String startLocation,
    required String endLocation,
    required int validDays,
    required Money price,
    required int availableSeats,
    required LicenseStatus status,
  }) = _LicensePreview;
}
