import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';

/// Events for the payment flow.
abstract class PaymentEvent {
  /// Constructor for [PaymentEvent].
  const PaymentEvent();
}

/// Start a Zain Cash payment for a subscription.
class PaymentStartZainCash extends PaymentEvent {
  /// Constructor for [PaymentStartZainCash].
  const PaymentStartZainCash({
    required this.routeId,
    required this.amount,
    required this.currency,
  });

  /// The ID of the route associated with this subscription payment.
  final RouteId routeId;

  /// The payment amount.
  final int amount;

  /// The currency code.
  final String currency;
}

/// Poll payment status (after redirect back from Zain Cash).
class PaymentPollStatus extends PaymentEvent {
  /// Constructor for [PaymentPollStatus].
  const PaymentPollStatus({required this.paymentId});

  /// The ID of the payment to poll status for.
  final String paymentId;
}

/// Reset the payment state.
class PaymentReset extends PaymentEvent {
  /// Constructor for [PaymentReset].
  const PaymentReset();
}

/// Internal event triggered when polling checks the payment status.
class PaymentStatusChanged extends PaymentEvent {
  /// Constructor for [PaymentStatusChanged].
  const PaymentStatusChanged({required this.result});

  /// The result of the payment status query (failure or current
  /// status details).
  final Either<Failure, PaymentInfo> result;
}

/// Resume an existing Zain Cash payment.
class PaymentResume extends PaymentEvent {
  /// Constructor for [PaymentResume].
  const PaymentResume({
    required this.paymentId,
    required this.paymentUrl,
    required this.amount,
    required this.currency,
  });

  /// The ID of the payment.
  final String paymentId;

  /// The payment URL.
  final String paymentUrl;

  /// The payment amount.
  final int amount;

  /// The currency code.
  final String currency;
}
