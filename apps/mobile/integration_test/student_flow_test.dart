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
    'Student E2E Flow: Login -> Navigate -> Search Route -> Map -> Generate QR -> Logout',
    ($) async {
      // 1. Setup App and Mocks
      final manager = await setupPatrolApp($);

      // 2. Login Flow
      expect($('تسجيل الدخول'), findsWidgets);

      // Input credentials
      await $(TextFormField).at(0).enterText('test@student.iq');
      await $(TextFormField).at(1).enterText('TestPass123!');

      // Dismiss keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await $.pumpAndSettle();

      // Override auth for successful sign in
      when(() => manager.auth.signInWithPassword(
              email: 'test@student.iq', password: 'TestPass123!'))
          .thenAnswer((_) async => Right(testStudent));
      when(() => manager.auth.currentUser).thenReturn(testStudent);
      when(() => manager.auth.fetchFullProfile())
          .thenAnswer((_) async => Right(testStudent));

      // Tap Login
      await $(PrimaryButton).containing('تسجيل الدخول').tap();

      // 3. Verify Home Navigation
      expect($('مرحباً، محمد'), findsOneWidget);
      expect($('نشط'), findsOneWidget);

      // 4. Tab Navigation (Routes)
      await $(Icons.directions_bus_outlined).tap();
      expect($('خط جامعة بغداد - الجادرية'), findsOneWidget);
      await $(TextField).enterText('بغداد');
      await $.pumpAndSettle();

      // 5. Tab Navigation (Active Trips Map)
      await $(Icons.map_outlined).tap();
      expect($('قيد السير'), findsOneWidget);

      // 6. Tab Navigation (Subscriptions)
      await $(Icons.confirmation_number_outlined).tap();
      expect($(RegExp('ينتهي.*')), findsOneWidget);

      // 7. Profile & Logout
      await $(Icons.person_outline).tap();

      expect($('محمد علي'), findsOneWidget);
      expect($('test@student.iq'), findsOneWidget);

      await $('تسجيل الخروج').scrollTo().tap();
      await $('إلغاء').tap(); // Test cancel

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
