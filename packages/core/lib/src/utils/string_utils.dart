/// Shared string extensions for the Sayr domain layer.
extension StringUtils on String {
  /// Convert snake_case to camelCase.
  ///
  /// Example: `'driver_waiting'` → `'driverWaiting'`
  String toCamelCase() {
    final parts = split('_');
    if (parts.length == 1) return this;
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
