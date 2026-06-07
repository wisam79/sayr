import 'package:fpdart/fpdart.dart';

import 'package:sayr_core/src/entities/payment_info.dart';
import 'package:sayr_core/src/failures/failure.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

/// Interface for payment operations repository.
abstract class PaymentRepository {
  /// Create a Zain Cash payment.
  Future<Either<Failure, PaymentInfo>> createPayment({
    required RouteId routeId,
    required int amount,
    required String currency,
    required String method,
  });

  /// Get payment status.
  Future<Either<Failure, PaymentInfo>> getPaymentStatus(
    String paymentId,
  );
}
