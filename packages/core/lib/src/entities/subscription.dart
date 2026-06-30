import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/enums/subscription_status.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'subscription.freezed.dart';

/// A student's subscription to a route.
@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    required SubscriptionId id,
    required UserId studentId,
    required RouteId routeId,
    required SubscriptionStatus status,
    required DateTime startDate,
    DateTime? endDate,
    DateTime? cancelledAt,
  }) = _Subscription;

  const Subscription._();

  /// Whether the subscription is currently valid.
  bool get isActive => status.isActive;

  /// Whether the subscription has expired.
  bool get isExpired {
    if (status == SubscriptionStatus.expired) return true;
    if (endDate == null) return false;
    return endDate!.isBefore(clock.now());
  }

  /// Days remaining until expiry.
  int? get daysRemaining {
    if (endDate == null) return null;
    final diff = endDate!.difference(clock.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
