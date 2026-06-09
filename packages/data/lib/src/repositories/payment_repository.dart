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
      return PaymentInfo.fromJson(response);
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
      return PaymentInfo.fromJson(response);
    });
  }
}
