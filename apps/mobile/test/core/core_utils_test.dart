import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/core/global_keys.dart';
import 'package:sayr_mobile/core/talker_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TestTalkerModule extends TalkerModule {}

void main() {
  group('Core Utilities', () {
    test('GlobalKeys scaffoldMessengerKey is initialized', () {
      expect(GlobalKeys.scaffoldMessengerKey, isA<GlobalKey<ScaffoldMessengerState>>());
    });

    test('TalkerModule provides Talker instance', () {
      final module = TestTalkerModule();
      final talker = module.talker;
      expect(talker, isA<Talker>());
    });
  });
}
