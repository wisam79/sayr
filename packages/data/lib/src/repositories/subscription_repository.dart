import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/subscription_model.dart';

/// Concrete implementation of SubscriptionRepository using Remote data source.
@LazySingleton(as: SubscriptionRepository)
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required RemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;
  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, List<Subscription>>> getMySubscriptions() async {
    try {
      final user = _remoteDatasource.currentUser;
      if (user == null) {
        return const Left(UnauthorizedFailure());
      }

      final response = await _remoteDatasource.getMySubscriptions(user.id);
      final subs = response
          .map((json) => SubscriptionModel.fromJson(json).toEntity())
          .toList();

      return Right<Failure, List<Subscription>>(subs);
    } catch (e) {
      return Left<Failure, List<Subscription>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, List<Subscription>>> getActiveSubscriptions() async {
    final result = await getMySubscriptions();
    return result.map(
      (List<Subscription> subs) =>
          subs.where((Subscription s) => s.isActive && !s.isExpired).toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> cancel(SubscriptionId id) async {
    try {
      await _remoteDatasource.cancelSubscription(id.value);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionId>> activateLicense(
    LicenseCode code,
  ) async {
    try {
      final response = await _remoteDatasource.activateLicense(code.value);
      return Right<Failure, SubscriptionId>(SubscriptionId(response));
    } catch (e) {
      final message = e.toString();
      if (message.contains('Too many activation attempts')) {
        return const Left(RateLimitFailure());
      }
      if (message.contains('already have an active subscription')) {
        return const Left(
          BusinessRuleFailure(
            message: 'لديك اشتراك نشط بالفعل على هذا الخط',
          ),
        );
      }
      if (message.contains('not active')) {
        return const Left(BusinessRuleFailure(message: 'الترخيص غير مفعّل'));
      }
      if (message.contains('not found')) {
        return const Left(NotFoundFailure(resource: 'license'));
      }
      return Left(ServerFailure(message: message));
    }
  }
}
