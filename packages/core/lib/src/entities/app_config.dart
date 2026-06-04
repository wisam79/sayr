import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

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

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  /// Whether the given version is below the minimum required.
  bool isVersionOutdated(String currentVersion) {
    return _compareVersions(currentVersion, minVersion) < 0;
  }

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
