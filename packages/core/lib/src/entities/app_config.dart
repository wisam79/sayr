import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
/// Application configuration (force update, maintenance mode, etc.)
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String minVersion,
    @Default(false) bool maintenanceMode,
    String? maintenanceMessage,
    String? updateUrl,
  }) = _AppConfig;

  const AppConfig._();

  /// Whether the given version is below the minimum required.
  bool isVersionOutdated(String currentVersion) {
    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Compares two semantic version strings (e.g. "1.2.3").
  ///
  /// Simple 3-part custom comparison implementation to avoid pulling in the heavy
  /// `pub_semver` dependency in the domain layer. Returns positive if a > b,
  /// negative if a < b, and 0 if equal.
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).toList();
    final bParts = b.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final aPart = i < aParts.length ? aParts[i] ?? 0 : 0;
      final bPart = i < bParts.length ? bParts[i] ?? 0 : 0;
      if (aPart != bPart) return aPart.compareTo(bPart);
    }
    return 0;
  }
}
