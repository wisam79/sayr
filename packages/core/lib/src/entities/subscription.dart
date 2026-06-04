import 'package:equatable/equatable.dart';

import '../enums/subscription_status.dart';
import '../value_objects/ids.dart';

/// A student's subscription to a route.
class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.studentId,
    required this.routeId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.cancelledAt,
  });

  /// Unique subscription ID.
  final SubscriptionId id;

  /// The student who holds this subscription.
  final UserId studentId;

  /// The subscribed route.
  final RouteId routeId;

  /// Current status.
  final SubscriptionStatus status;

  /// When the subscription was activated.
  final DateTime startDate;

  /// When the subscription expires (null = indefinite).
  final DateTime? endDate;

  /// When the subscription was cancelled (if applicable).
  final DateTime? cancelledAt;

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

  @override
  List<Object?> get props => [
        id,
        studentId,
        routeId,
        status,
        startDate,
        endDate,
        cancelledAt,
      ];
}
