import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'payment_state.freezed.dart';

/// States for the payment flow.
@freezed
sealed class PaymentState with _$PaymentState {
  const factory PaymentState.initial() = PaymentInitial;

  const factory PaymentState.loading({String? message}) = PaymentLoading;

  const factory PaymentState.urlReady({
    required String paymentUrl,
    required String paymentId,
    required int amount,
    required String currency,
  }) = PaymentUrlReady;

  const factory PaymentState.awaitingCompletion({required String paymentId}) =
      PaymentAwaitingCompletion;

  const factory PaymentState.success({required SubscriptionId subscriptionId}) =
      PaymentSuccess;

  const factory PaymentState.failed({required Failure failure}) = PaymentFailed;
}
