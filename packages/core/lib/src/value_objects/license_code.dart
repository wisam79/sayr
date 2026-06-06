import 'package:equatable/equatable.dart';

/// An 8-character license code used to activate route subscriptions.
///
/// Format: 8 uppercase alphanumeric characters (e.g., "A1B2C3D4").
class LicenseCode extends Equatable {
  /// Create a [LicenseCode] from a raw string. Throws if invalid.
  factory LicenseCode(String input) {
    final code = tryParse(input);
    if (code == null) {
      throw ArgumentError.value(
        input,
        'input',
        'License code must be exactly 8 uppercase alphanumeric characters',
      );
    }
    return code;
  }
  const LicenseCode._(this.value);

  /// Create a [LicenseCode] from a raw string. Returns null if invalid.
  static LicenseCode? tryParse(String input) {
    final cleaned = input.trim().toUpperCase();
    if (cleaned.length != 8) return null;
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(cleaned)) return null;
    return LicenseCode._(cleaned);
  }

  /// The license code value (8 chars, uppercase).
  final String value;

  /// Display formatted with a dash separator (e.g., "A1B2-C3D4").
  String get formatted {
    return '${value.substring(0, 4)}-${value.substring(4)}';
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'LicenseCode($value)';
}
