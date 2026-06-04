import '../utils/string_utils.dart';

/// Support request status.
enum SupportStatus {
  /// Newly created
  open,

  /// Admin is working on it
  inProgress,

  /// Resolved and closed
  closed;

  /// Parse from database string value.
  static SupportStatus fromString(String value) {
    final normalized = value.toCamelCase();
    return SupportStatus.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => SupportStatus.open,
    );
  }
}
