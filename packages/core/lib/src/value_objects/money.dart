import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Represents a monetary amount in Iraqi Dinar (IQD).
///
/// Stored as integer (no floating point arithmetic).
class Money extends Equatable {
  /// Create a Money from integer IQD.
  const Money(this.amount);

  /// Amount in IQD.
  final int amount;

  /// Zero money.
  static const Money zero = Money(0);

  /// Add two Money values.
  Money operator +(Money other) => Money(amount + other.amount);

  /// Subtract two Money values.
  Money operator -(Money other) => Money(amount - other.amount);

  /// Multiply by a scalar.
  Money operator *(int multiplier) => Money(amount * multiplier);

  /// Whether this amount is greater than the other.
  bool operator >(Money other) => amount > other.amount;

  /// Whether this amount is less than the other.
  bool operator <(Money other) => amount < other.amount;

  /// Whether this amount is greater than or equal to the other.
  bool operator >=(Money other) => amount >= other.amount;

  /// Whether this amount is less than or equal to the other.
  bool operator <=(Money other) => amount <= other.amount;

  /// Whether the amount is zero.
  bool get isZero => amount == 0;

  /// Whether the amount is positive.
  bool get isPositive => amount > 0;

  /// Whether the amount is negative.
  bool get isNegative => amount < 0;

  /// Get the amount in IQD.
  int get inIQD => amount;

  /// Format as currency string.
  ///
  /// Uses `NumberFormat.currency` from the intl package for locale-aware
  /// thousand separators. [locale] defaults to `'ar_IQ'`; [symbol] defaults
  /// to `'د.ع'`.
  String format({String? locale, String symbol = 'د.ع'}) {
    return NumberFormat.currency(
      locale: locale ?? 'ar_IQ',
      symbol: symbol,
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  List<Object?> get props => [amount];

  @override
  String toString() => 'Money($amount)';
}
