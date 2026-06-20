import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:patrol/patrol.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/app.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/routing/app_router.dart';

void main() {
  patrolTest(
    'Sayr App Onboarding and Login Navigation E2E',
    ($) async {
      // 1. Initialize local assets/databases
      await Hive.initFlutter();
      final box = await Hive.openBox<String>('settings_box');
      await box.clear();

      // 2. Initialize Supabase client
      try {
        await SayrSupabase.instance.init();
      } catch (_) {}

      // 3. Initialize DI
      await initDependencies();

      // 4. Launch App
      final authBloc = sl<AuthBloc>();
      final appRouter = AppRouter(authBloc: authBloc);
      await $
          .pumpWidgetAndSettle(SayrApp(router: appRouter, authBloc: authBloc));

      // 5. Check if Splash / Onboarding skip is visible and tap it
      if (find.text('تخطي').evaluate().isNotEmpty) {
        await $.tap(find.text('تخطي'));
        await $.pumpAndSettle();
      }

      // 6. Verify we are on LoginPage
      expect(find.text('تسجيل الدخول'), findsWidgets);
    },
  );
}
