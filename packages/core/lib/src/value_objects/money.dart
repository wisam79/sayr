import 'package:equatable/equatable.dart';

/// Represents a monetary amount in Iraqi Dinar (IQD).
///
/// Stored as integer (no floating point arithmetic).
class Money extends Equatable {
  /// Amount in fils (1 IQD = 1000 fils conceptually, but we store as whole IQD)
  final int amountInFils;

  /// Create a Money from integer IQD.
  const Money(this.amountInFils);

  /// Zero money.
  static const Money zero = Money(0);

  /// Add two Money values.
  Money operator +(Money other) => Money(amountInFils + other.amountInFils);

  /// Subtract two Money values.
  Money operator -(Money other) => Money(amountInFils - other.amountInFils);

  /// Multiply by a scalar.
  Money operator *(int multiplier) => Money(amountInFils * multiplier);

  /// Whether this amount is greater than the other.
  bool operator >(Money other) => amountInFils > other.amountInFils;

  /// Whether this amount is less than the other.
  bool operator <(Money other) => amountInFils < other.amountInFils;

  /// Whether this amount is greater than or equal to the other.
  bool operator >=(Money other) => amountInFils >= other.amountInFils;

  /// Whether this amount is less than or equal to the other.
  bool operator <=(Money other) => amountInFils <= other.amountInFils;

  /// Whether the amount is zero.
  bool get isZero => amountInFils == 0;

  /// Whether the amount is positive.
  bool get isPositive => amountInFils > 0;

  /// Whether the amount is negative.
  bool get isNegative => amountInFils < 0;

  /// Get the amount in IQD.
  int get inIQD => amountInFils;

  /// Format as currency string (IQD).
  String format({String locale = 'ar'}) {
    final formatted = amountInFils.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatted د.ع';
  }

  @override
  List<Object?> get props => [amountInFils];

  @override
  String toString() => 'Money($amountInFils)';
}
