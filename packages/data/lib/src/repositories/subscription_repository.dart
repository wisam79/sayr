import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../supabase/supabase_client.dart';

/// Repository for subscription operations.
@lazySingleton
class SubscriptionRepository {
  SubscriptionRepository({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// Get all subscriptions for the current user.
  Future<Either<Failure, List<Subscription>>> getMySubscriptions() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) {
        return const Left(UnauthorizedFailure());
      }

      final response = await _supabase.client
          .from('subscriptions')
          .select()
          .eq('student_id', user.id)
          .order('start_date', ascending: false);

      final subs = (response as List<dynamic>)
          .map<Subscription>((dynamic json) => _fromJson(json as Map<String, dynamic>))
          .toList();

      return Right<Failure, List<Subscription>>(subs);
    } catch (e) {
      return Left<Failure, List<Subscription>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Get active subscriptions.
  Future<Either<Failure, List<Subscription>>> getActiveSubscriptions() async {
    final result = await getMySubscriptions();
    return result.map(
      (List<Subscription> subs) =>
          subs.where((Subscription s) => s.isActive && !s.isExpired).toList(),
    );
  }

  /// Cancel a subscription.
  Future<Either<Failure, Unit>> cancel(SubscriptionId id) async {
    try {
      await _supabase.client.rpc<void>(
        'cancel_subscription',
        params: {'p_subscription_id': id.value},
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  /// Activate a license code (creates a pending subscription).
  Future<Either<Failure, SubscriptionId>> activateLicense(LicenseCode code) async {
    try {
      final response = await _supabase.client.rpc<String>(
        'activate_license',
        params: {'p_code': code.value},
      );
      return Right<Failure, SubscriptionId>(SubscriptionId(response));
    } catch (e) {
      final message = e.toString();
      if (message.contains('Too many activation attempts')) {
        return const Left(RateLimitFailure());
      }
      if (message.contains('already have an active subscription')) {
        return const Left(BusinessRuleFailure(
          message: 'لديك اشتراك نشط بالفعل على هذا الخط',
        ));
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

  Subscription _fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: SubscriptionId(json['id'] as String),
      studentId: UserId(json['student_id'] as String),
      routeId: RouteId(json['route_id'] as String),
      status: SubscriptionStatus.fromString(json['status'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
    );
  }
}
