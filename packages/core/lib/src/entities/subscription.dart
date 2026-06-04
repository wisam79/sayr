import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/subscription_status.dart';
import '../value_objects/ids.dart';
import '../utils/json_converters.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// A student's subscription to a route.
@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    @JsonKey(fromJson: subscriptionIdFromJson, toJson: subscriptionIdToJson)
    required SubscriptionId id,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId studentId,
    @JsonKey(fromJson: routeIdFromJson, toJson: routeIdToJson)
    required RouteId routeId,
    @JsonKey(
        fromJson: subscriptionStatusFromJson, toJson: subscriptionStatusToJson)
    required SubscriptionStatus status,
    required DateTime startDate,
    DateTime? endDate,
    DateTime? cancelledAt,
  }) = _Subscription;

  const Subscription._();

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  /// Whether the subscription is currently valid.
  bool get isActive => status.isActive;

  /// Whether the subscription has expired.
  bool get isExpired {
    if (status == SubscriptionStatus.expired) return true;
    if (endDate == null) return false;
    return endDate!.isBefore(DateTime.now());
  }

  /// Days remaining until expiry.
  int? get daysRemaining {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
