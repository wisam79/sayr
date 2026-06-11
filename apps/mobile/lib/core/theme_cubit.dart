import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';

/// Cubit responsible for managing and persisting the application's theme mode.
class ThemeCubit extends Cubit<ThemeMode> {
  /// Creates a [ThemeCubit] with the default system theme mode.
  ThemeCubit() : super(ThemeMode.system);

  static const _boxName = 'settings_box';
  static const _key = 'sayr_theme_mode';

  /// Loads the persisted theme mode from Hive.
  Future<void> load() async {
    final box = await Hive.openBox<String>(_boxName);
    if (isClosed) return;
    final modeString = box.get(_key);
    if (modeString != null) {
      final mode = ThemeMode.values.firstWhere(
        (e) => e.name == modeString,
        orElse: () => ThemeMode.system,
      );
      emit(mode);
    }
  }

  /// Persists and emits a new [themeMode].
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, themeMode.name);
    if (isClosed) return;
    emit(themeMode);
  }
}
