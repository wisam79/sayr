/// Subscription status - states of a student subscription on a route.
enum SubscriptionStatus {
  /// Active subscription - student can board any trip on this route
  active,

  /// Pending activation (during processing)
  pending,

  /// Expired (past end_date)
  expired,

  /// Cancelled by student or admin
  cancelled;

  /// Whether the subscription is currently usable.
  bool get isActive {
    return this == SubscriptionStatus.active;
  }

  /// Parse from database string value.
  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionStatus.expired,
    );
  }
}
