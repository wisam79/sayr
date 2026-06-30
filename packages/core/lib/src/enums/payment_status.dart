/// Payment transaction status.
enum PaymentStatus {
  /// Payment has been initiated but not completed
  pending,

  /// Payment completed successfully
  completed,

  /// Payment failed or was rejected
  failed,

  /// Payment was cancelled by the user
  cancelled;

  /// Parse from database string value.
  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown PaymentStatus: $value'),
    );
  }
}
