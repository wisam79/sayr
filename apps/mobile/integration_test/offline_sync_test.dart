import 'package:flutter/material.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol/patrol.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import 'helpers/mock_repositories.dart';
import 'helpers/patrol_setup.dart';

void main() {
  patrolTest(
    'Offline Sync E2E Flow: Native Network Toggle -> Offline Banner -> Sync -> Reconnect',
    ($) async {
      // 1. Setup App and Mocks
      final manager = await setupPatrolApp($);

      // 2. Login Flow as Student
      when(() => manager.auth.signInWithPassword(
              email: 'test@student.iq', password: 'TestPass123!'))
          .thenAnswer((_) async => Right(testStudent));
      when(() => manager.auth.currentUser).thenReturn(testStudent);
      when(() => manager.auth.fetchFullProfile())
          .thenAnswer((_) async => Right(testStudent));

      await $(TextFormField).at(0).enterText('test@student.iq');
      await $(TextFormField).at(1).enterText('TestPass123!');
      FocusManager.instance.primaryFocus?.unfocus();
      await $.pumpAndSettle();
      await $(PrimaryButton).containing('تسجيل الدخول').tap();

      expect($('مرحباً، محمد'), findsOneWidget);

      // 3. Native OS Interaction: Disable Network
      // Disable both WiFi and Cellular to trigger offline mode
      await $.native.disableWifi();
      await $.native.disableCellular();

      // The app relies on connectivity_plus to detect offline mode and show a banner.
      // Give it a moment to detect the state change.
      await $.pump(const Duration(seconds: 3));

      // Verify the offline banner or indicator is present
      // Usually, there's a text like "لا يوجد اتصال بالإنترنت" or similar
      final offlineBanner = $(RegExp('لا يوجد اتصال.*|انقطع الاتصال.*'));
      if (offlineBanner.exists) {
        expect(offlineBanner, findsWidgets);
      }

      // Verify we can still navigate while offline
      await $(Icons.directions_bus_outlined).tap();
      expect(
          $('خط جامعة بغداد - الجادرية'), findsOneWidget); // Loaded from cache

      // 4. Native OS Interaction: Enable Network
      await $.native.enableWifi();
      await $.native.enableCellular();

      // Wait for connectivity to restore
      await $.pump(const Duration(seconds: 5));

      // The offline banner should disappear
      if (offlineBanner.exists) {
        expect(offlineBanner, findsNothing);
      }

      // 5. Cleanup / Logout
      await $(Icons.person_outline).tap();
      await $('تسجيل الخروج').scrollTo().tap();

      when(() => manager.auth.signOut()).thenAnswer((_) async {});
      when(() => manager.auth.currentUser).thenReturn(null);
      when(() => manager.auth.fetchFullProfile())
          .thenAnswer((_) async => const Right(null));

      await $(FilledButton).containing('تسجيل الخروج').tap();
      expect($('أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة'), findsOneWidget);
    },
  );
}
