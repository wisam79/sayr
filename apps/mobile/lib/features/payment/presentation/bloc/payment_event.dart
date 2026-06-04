import 'package:sayr_core/sayr_core.dart';

/// Events for the payment flow.
abstract class PaymentEvent {
  const PaymentEvent();
}

/// Start a Zain Cash payment for a subscription.
class PaymentStartZainCash extends PaymentEvent {
  const PaymentStartZainCash({
    required this.routeId,
    required this.amount,
    required this.currency,
  });

  final RouteId routeId;
  final int amount;
  final String currency;
}

/// Poll payment status (after redirect back from Zain Cash).
class PaymentPollStatus extends PaymentEvent {
  const PaymentPollStatus({required this.paymentId});
  final String paymentId;
}

/// Reset the payment state.
class PaymentReset extends PaymentEvent {
  const PaymentReset();
}
