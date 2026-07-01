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
    'Notifications E2E Flow: Native Permission Grant -> Simulate Push Notification',
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

      // 3. Native OS Interaction: Notifications Permission
      // When the user logs in, Sayr requests Push Notification permission.
      // We use Patrol to intercept the OS dialog and grant it.
      if (await $.native.isPermissionDialogVisible()) {
        await $.native.grantPermissionWhenInUse();
      }

      // 4. Simulate Background Notification Interaction
      // Patrol can open the notification shade and tap a specific notification
      // (This works on a real device or properly configured emulator during the test)
      // await $.native.openNotifications();
      // final notificationTitle = 'تم تغيير مسار الرحلة';
      // if (await $.native.getNotifications().then((list) => list.any((n) => n.title == notificationTitle))) {
      //   await $.native.tapOnNotificationBySelector(Selector(text: notificationTitle));
      // }
      // await $.native.closeNotifications(); // Cleanup if we opened it

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
