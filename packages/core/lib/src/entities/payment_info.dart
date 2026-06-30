import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/payment_status.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/money.dart';

part 'payment_info.freezed.dart';
/// Payment info value object (freezed).
@freezed
abstract class PaymentInfo with _$PaymentInfo {
  const factory PaymentInfo({
    required PaymentId id,
    required PaymentStatus status,
    required Money amount,
    @Default('') String paymentUrl,
    @Default('IQD') String currency,
    SubscriptionId? subscriptionId,
    RouteId? routeId,
  }) = _PaymentInfo;

  }
