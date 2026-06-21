import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Concrete implementation of SubscriptionRepository using Remote data source.
@LazySingleton(as: SubscriptionRepository)
class SubscriptionRepositoryImpl extends BaseRepository
    implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required super.talker,
  }) : _remoteDatasource = remoteDatasource;
  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, List<Subscription>>> getMySubscriptions() async {
    return guard(() async {
      final user = _remoteDatasource.currentUser;
      if (user == null) {
        throw const UnauthorizedFailure();
      }

      final response = await _remoteDatasource.getMySubscriptions(user.id);
      return response.map((model) => model.toEntity()).toList();
    });
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
    return guard(() async {
      await _remoteDatasource.cancelSubscription(id.value);
      return unit;
    });
  }

  @override
  Future<Either<Failure, SubscriptionId>> activateLicense(
    LicenseCode code,
  ) async {
    return guard(
      () async {
        final response = await _remoteDatasource.activateLicense(code.value);
        return SubscriptionId(response);
      },
      errorMapper: (e) {
        final message =
            e is supabase.PostgrestException ? e.message : e.toString();
        if (message.contains('Too many activation attempts')) {
          return const RateLimitFailure();
        }
        if (message.contains('already have an active subscription')) {
          return const BusinessRuleFailure(
            message: 'already_has_active_subscription',
          );
        }
        if (message.contains('not active')) {
          return const BusinessRuleFailure(message: 'license_not_active');
        }
        if (message.contains('not found')) {
          return const NotFoundFailure(resource: 'license');
        }
        return mapException(e);
      },
    );
  }

  @override
  Future<Either<Failure, LicensePreview>> getLicenseDetails(
    LicenseCode code,
  ) async {
    return guard(() async {
      final response = await _remoteDatasource.getLicenseDetails(code.value);
      return LicensePreview.fromJson(response);
    }).then(
      (result) => result.fold<Either<Failure, LicensePreview>>(
        (failure) {
          final message = failure.message ?? '';
          if (message.contains('Too many attempts')) {
            return const Left(RateLimitFailure());
          }
          if (message.contains('not active')) {
            return const Left(
              BusinessRuleFailure(message: 'license_not_active'),
            );
          }
          if (message.contains('already used')) {
            return const Left(
              BusinessRuleFailure(message: 'license_already_used'),
            );
          }
          if (message.contains('not found')) {
            return const Left(NotFoundFailure(resource: 'license'));
          }
          if (message.contains('Invalid license code format')) {
            return const Left(
              ValidationFailure(message: 'invalid_license_code'),
            );
          }
          return Left(failure);
        },
        Right.new,
      ),
    );
  }
}
