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
    'Driver E2E Flow: Login -> Location Permission -> Active Trips -> Complete Trip',
    ($) async {
      // 1. Setup App and Mocks
      final manager = await setupPatrolApp($);

      // 2. Login Flow
      expect($('تسجيل الدخول'), findsWidgets);

      // Input credentials
      await $(TextFormField).at(0).enterText('test@driver.iq');
      await $(TextFormField).at(1).enterText('TestPass123!');

      // Dismiss keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await $.pumpAndSettle();

      // Override auth for successful sign in
      when(() => manager.auth.signInWithPassword(
          email: 'test@driver.iq',
          password: 'TestPass123!')).thenAnswer((_) async => Right(testDriver));
      when(() => manager.auth.currentUser).thenReturn(testDriver);
      when(() => manager.auth.fetchFullProfile())
          .thenAnswer((_) async => Right(testDriver));

      // Tap Login
      await $(PrimaryButton).containing('تسجيل الدخول').tap();

      // 3. Verify Home Navigation
      expect($('مرحباً، أحمد'), findsOneWidget);
      expect($('رحلاتي النشطة'), findsOneWidget);

      // 4. Navigate to Active Trips
      await $('رحلاتي النشطة').tap();
      expect($('قيد السير'), findsWidgets);

      // 5. Native OS Interaction: Location Permission Handling
      // When a driver starts navigating or enters a trip, the app requests location permissions.
      // We can simulate granting permissions via Patrol's native interactions.

      // Tap the first active trip
      await $('قيد السير').first.tap();

      // The app might request location permission here if not already granted
      if (await $.native.isPermissionDialogVisible()) {
        await $.native.grantPermissionWhenInUse();
      }

      expect($('تحكم بالرحلة'), findsOneWidget);

      // 6. Complete Trip
      final completeButton = $('أكمل');
      if (completeButton.exists) {
        await completeButton.tap();
      }

      // 7. Profile & Logout
      // Navigate back to home
      await $.pumpAndSettle();
      await $(Icons.home_outlined).tap();

      // Navigate to profile tab
      await $(Icons.person_outline).tap();

      expect($('أحمد السائق'), findsOneWidget);

      await $('تسجيل الخروج').scrollTo().tap();

      when(() => manager.auth.signOut()).thenAnswer((_) async {});
      when(() => manager.auth.currentUser).thenReturn(null);
      when(() => manager.auth.fetchFullProfile())
          .thenAnswer((_) async => const Right(null));

      await $(FilledButton).containing('تسجيل الخروج').tap();

      // 8. Verify back at login
      expect($('أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة'), findsOneWidget);
    },
  );
}
