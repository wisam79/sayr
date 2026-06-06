import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/payout_status.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/money.dart';

part 'payout.freezed.dart';
part 'payout.g.dart';

/// A driver's payout request.
@freezed
abstract class Payout with _$Payout {
  const factory Payout({
    @JsonKey(fromJson: payoutIdFromJson, toJson: payoutIdToJson)
    required PayoutId id,
    @JsonKey(fromJson: driverIdFromJson, toJson: driverIdToJson)
    required DriverId driverId,
    @JsonKey(fromJson: moneyFromJson, toJson: moneyToJson)
    required Money amount,
    @JsonKey(fromJson: payoutStatusFromJson, toJson: payoutStatusToJson)
    required PayoutStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? referenceNote,
  }) = _Payout;

  const Payout._();

  factory Payout.fromJson(Map<String, dynamic> json) => _$PayoutFromJson(json);

  /// Whether the payout is awaiting review.
  bool get isPending => status.isPending;
}
