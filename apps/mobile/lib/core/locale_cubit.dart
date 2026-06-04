import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('ar'));

  static const _key = 'sayr_locale';
  static const supportedLanguageCodes = {'ar', 'en'};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && supportedLanguageCodes.contains(code)) {
      emit(Locale(code));
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (!supportedLanguageCodes.contains(code)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    emit(Locale(code));
  }
}
