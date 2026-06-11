import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_info.freezed.dart';
part 'payment_info.g.dart';

/// Payment info value object (freezed).
@freezed
abstract class PaymentInfo with _$PaymentInfo {
  const factory PaymentInfo({
    required String id,
    required String status,
    required int amount,
    @Default('') @JsonKey(name: 'payment_url') String paymentUrl,
    @Default('IQD') String currency,
    @Default('') @JsonKey(name: 'subscription_id') String subscriptionId,
    @Default('') @JsonKey(name: 'route_id') String routeId,
  }) = _PaymentInfo;

  factory PaymentInfo.fromJson(Map<String, dynamic> json) =>
      _$PaymentInfoFromJson(json);
}
