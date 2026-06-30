import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'payment_info.freezed.dart';
part 'payment_info.g.dart';

/// DTO for PaymentInfo from Supabase (freezed version).
@freezed
abstract class PaymentInfoModel with _$PaymentInfoModel {
  const factory PaymentInfoModel({
    required String id,
    required String status,
    required int amount,
    @JsonKey(name: 'payment_url') @Default('') String paymentUrl,
    @Default('IQD') String currency,
    @JsonKey(name: 'subscription_id') String? subscriptionId,
    @JsonKey(name: 'route_id') String? routeId,
  }) = _PaymentInfoModel;

  const PaymentInfoModel._();

  factory PaymentInfoModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentInfoModelFromJson(json);

  /// Convert to a domain entity.
  PaymentInfo toEntity() => PaymentInfo(
        id: PaymentId(id),
        status: PaymentStatus.fromString(status),
        amount: Money(amount),
        paymentUrl: paymentUrl,
        currency: currency,
        subscriptionId:
            subscriptionId != null ? SubscriptionId(subscriptionId!) : null,
        routeId: routeId != null ? RouteId(routeId!) : null,
      );
}
