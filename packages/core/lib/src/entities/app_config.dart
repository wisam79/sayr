import 'package:equatable/equatable.dart';

/// Application configuration (force update, maintenance mode, etc.)
class AppConfig extends Equatable {
  const AppConfig({
    required this.minVersion,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.updateUrl,
  });

  /// Minimum required app version (e.g., "3.0.0").
  final String minVersion;

  /// Whether maintenance mode is enabled.
  final bool maintenanceMode;

  /// Message shown in maintenance mode.
  final String? maintenanceMessage;

  /// URL to download the latest version.
  final String? updateUrl;

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

  @override
  List<Object?> get props => [
        minVersion,
        maintenanceMode,
        maintenanceMessage,
        updateUrl,
      ];
}
