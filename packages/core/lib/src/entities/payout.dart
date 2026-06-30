import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/payout_status.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/money.dart';

part 'payout.freezed.dart';
/// A driver's payout request.
@freezed
abstract class Payout with _$Payout {
  const factory Payout({
    required PayoutId id,
    required DriverId driverId,
    required Money amount,
    required PayoutStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? referenceNote,
  }) = _Payout;

  const Payout._();

  /// Whether the payout is awaiting review.
  bool get isPending => status.isPending;
}
