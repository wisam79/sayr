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

extension on String {
  /// Convert snake_case to camelCase.
  String toCamelCase() {
    final parts = split('_');
    if (parts.length == 1) return this;
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
