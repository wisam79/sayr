import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sayr_mobile/core/theme_cubit.dart';

void main() {
  late String hivePath;

  setUpAll(() async {
    hivePath = '${Directory.systemTemp.path}/hive_theme_test_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(hivePath);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    Hive.init(hivePath);
  });

  group('ThemeCubit', () {
    test('initial state is ThemeMode.system', () {
      final cubit = ThemeCubit();
      expect(cubit.state, ThemeMode.system);
      cubit.close();
    });

    blocTest<ThemeCubit, ThemeMode>(
      'setThemeMode emits dark mode',
      build: ThemeCubit.new,
      act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
      expect: () => [ThemeMode.dark],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setThemeMode emits light mode',
      build: ThemeCubit.new,
      act: (cubit) => cubit.setThemeMode(ThemeMode.light),
      expect: () => [ThemeMode.light],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'setThemeMode persists and load reads back',
      build: ThemeCubit.new,
      act: (cubit) async {
        await cubit.setThemeMode(ThemeMode.dark);
      },
      verify: (_) async {
        final cubit2 = ThemeCubit();
        await cubit2.load();
        expect(cubit2.state, ThemeMode.dark);
        await cubit2.close();
      },
    );
  });
}
