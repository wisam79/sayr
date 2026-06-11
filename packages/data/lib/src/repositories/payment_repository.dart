import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Concrete implementation of [PaymentRepository] using the remote datasource.
@LazySingleton(as: PaymentRepository)
class PaymentRepositoryImpl extends BaseRepository
    implements PaymentRepository {
  PaymentRepositoryImpl({required RemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, PaymentInfo>> createPayment({
    required RouteId routeId,
    required int amount,
    required String currency,
    required String method,
  }) async {
    return guard(() async {
      final response = await _remoteDatasource.createPayment(
        routeId: routeId.value,
        amount: amount,
        currency: currency,
        method: method,
      );
      final mappedResponse = Map<String, dynamic>.from(response);
      mappedResponse['payment_url'] = response['reference_url'];
      return PaymentInfo.fromJson(mappedResponse);
    });
  }

  @override
  Future<Either<Failure, PaymentInfo>> getPaymentStatus(
    String paymentId,
  ) async {
    return guard(() async {
      final response = await _remoteDatasource.getPaymentStatus(paymentId);
      if (response == null) {
        throw const NotFoundFailure(resource: 'payment');
      }
      final mappedResponse = Map<String, dynamic>.from(response);
      mappedResponse['payment_url'] = response['reference_url'];
      return PaymentInfo.fromJson(mappedResponse);
    });
  }

  @override
  Future<Either<Failure, List<PaymentInfo>>> getPendingPayments() async {
    return guard(() async {
      final response = await _remoteDatasource.getPendingPayments();
      return response.map((json) {
        final mapped = Map<String, dynamic>.from(json);
        mapped['payment_url'] = json['reference_url'];
        return PaymentInfo.fromJson(mapped);
      }).toList();
    });
  }
}
