import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit responsible for managing and persisting the application's locale.
class LocaleCubit extends Cubit<Locale> {
  /// Creates a [LocaleCubit] with the default Arabic locale.
  LocaleCubit() : super(const Locale('ar'));

  static const _key = 'sayr_locale';

  /// The set of supported language codes for the application.
  static const supportedLanguageCodes = {'ar', 'en'};

  /// Loads the persisted locale from [SharedPreferences] and emits it
  /// if supported.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && supportedLanguageCodes.contains(code)) {
      emit(Locale(code));
    }
  }

  /// Persists and emits a new [locale] if it is supported.
  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (!supportedLanguageCodes.contains(code)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    emit(Locale(code));
  }
}
