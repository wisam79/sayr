import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/money.dart';

part 'license_preview.freezed.dart';
part 'license_preview.g.dart';

/// Pre-activation preview details of a license code.
@freezed
abstract class LicensePreview with _$LicensePreview {
  const factory LicensePreview({
    @JsonKey(fromJson: licenseIdFromJson, toJson: licenseIdToJson)
    required LicenseId licenseId,
    @JsonKey(fromJson: routeIdFromJson, toJson: routeIdToJson)
    required RouteId routeId,
    required String routeTitle,
    required String startLocation,
    required String endLocation,
    required int validDays,
    @JsonKey(fromJson: moneyFromJson, toJson: moneyToJson)
    required Money price,
    required int availableSeats,
    required String status,
  }) = _LicensePreview;

  factory LicensePreview.fromJson(Map<String, dynamic> json) =>
      _$LicensePreviewFromJson(json);
}
