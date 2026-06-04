/// Driver payout request status.
enum PayoutStatus {
  /// Awaiting admin approval
  pending,

  /// Approved and paid
  completed,

  /// Rejected by admin
  rejected;

  /// Whether the payout is awaiting review.
  bool get isPending => this == PayoutStatus.pending;

  /// Parse from database string value.
  static PayoutStatus fromString(String value) {
    return PayoutStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PayoutStatus.pending,
    );
  }
}
