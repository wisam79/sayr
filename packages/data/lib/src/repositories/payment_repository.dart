import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';

/// Concrete implementation of [PaymentRepository] using the remote datasource.
@LazySingleton(as: PaymentRepository)
class PaymentRepositoryImpl implements PaymentRepository {
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
    try {
      final response = await _remoteDatasource.createPayment(
        routeId: routeId.value,
        amount: amount,
        currency: currency,
        method: method,
      );
      return Right<Failure, PaymentInfo>(PaymentInfo.fromJson(response));
    } catch (e) {
      return Left<Failure, PaymentInfo>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentInfo>> getPaymentStatus(
    String paymentId,
  ) async {
    try {
      final response = await _remoteDatasource.getPaymentStatus(paymentId);
      if (response == null) {
        return const Left<Failure, PaymentInfo>(
          NotFoundFailure(resource: 'payment'),
        );
      }
      return Right<Failure, PaymentInfo>(PaymentInfo.fromJson(response));
    } catch (e) {
      return Left<Failure, PaymentInfo>(ServerFailure(message: e.toString()));
    }
  }
}
