import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'license_preview.freezed.dart';
part 'license_preview.g.dart';

/// Pre-activation preview details of a license code.
@freezed
abstract class LicensePreviewModel with _$LicensePreviewModel {
  const factory LicensePreviewModel({
    @JsonKey(name: 'license_id') required String licenseId,
    @JsonKey(name: 'route_id') required String routeId,
    @JsonKey(name: 'route_title') required String routeTitle,
    @JsonKey(name: 'start_location') required String startLocation,
    @JsonKey(name: 'end_location') required String endLocation,
    @JsonKey(name: 'valid_days') required int validDays,
    required int price,
    @JsonKey(name: 'available_seats') required int availableSeats,
    required String status,
  }) = _LicensePreviewModel;

  const LicensePreviewModel._();

  factory LicensePreviewModel.fromJson(Map<String, dynamic> json) =>
      _$LicensePreviewModelFromJson(json);

  /// Convert to domain entity.
  LicensePreview toEntity() => LicensePreview(
        licenseId: LicenseId(licenseId),
        routeId: RouteId(routeId),
        routeTitle: routeTitle,
        startLocation: startLocation,
        endLocation: endLocation,
        validDays: validDays,
        price: Money(price),
        availableSeats: availableSeats,
        status: LicenseStatus.fromString(status),
      );
}
