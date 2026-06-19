import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sayr_mobile/core/locale_cubit.dart';

void main() {
  late String hivePath;

  setUpAll(() async {
    hivePath =
        '${Directory.systemTemp.path}/hive_locale_test_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(hivePath);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    Hive.init(hivePath);
  });

  group('LocaleCubit', () {
    test('initial state is Arabic locale', () {
      final cubit = LocaleCubit();
      expect(cubit.state, const Locale('ar'));
      cubit.close();
    });

    blocTest<LocaleCubit, Locale>(
      'setLocale emits English locale',
      build: LocaleCubit.new,
      act: (cubit) => cubit.setLocale(const Locale('en')),
      expect: () => [const Locale('en')],
    );

    blocTest<LocaleCubit, Locale>(
      'setLocale with unsupported language does not emit',
      build: LocaleCubit.new,
      act: (cubit) => cubit.setLocale(const Locale('fr')),
      expect: () => <Locale>[],
    );

    blocTest<LocaleCubit, Locale>(
      'setLocale persists and load reads back',
      build: LocaleCubit.new,
      act: (cubit) async {
        await cubit.setLocale(const Locale('en'));
      },
      verify: (_) async {
        final cubit2 = LocaleCubit();
        await cubit2.load();
        expect(cubit2.state, const Locale('en'));
        await cubit2.close();
      },
    );

    test('supportedLanguageCodes contains ar and en', () {
      expect(LocaleCubit.supportedLanguageCodes, containsAll(['ar', 'en']));
      expect(LocaleCubit.supportedLanguageCodes, hasLength(2));
    });
  });
}
