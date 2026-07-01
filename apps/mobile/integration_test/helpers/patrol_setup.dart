import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:patrol/patrol.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/app.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/routing/app_router.dart';

import 'mock_repositories.dart';

/// Prepares the application for a Patrol E2E test.
/// Returns the initialized `MockManager` to allow test-specific overrides.
Future<MockManager> setupPatrolApp(PatrolIntegrationTester $) async {
  // 1. Initialize local databases
  await Hive.initFlutter();
  final box = await Hive.openBox<String>('settings_box');
  await box.clear();

  // 2. Initialize Firebase (mocked/safely handled in E2E)
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  // 3. Initialize Supabase
  try {
    await SayrSupabase.instance.init();
  } catch (_) {}

  // 4. Register Dependencies
  await initDependencies();

  // 5. Setup Mocks
  registerFallbackValues();
  final manager = MockManager();
  manager.setupDefaultStubs();

  // Override actual implementations with our mocks
  sl
    ..allowReassignment = true
    ..registerSingleton<AuthRepository>(manager.auth)
    ..registerSingleton<RouteRepository>(manager.route)
    ..registerSingleton<SubscriptionRepository>(manager.subscription)
    ..registerSingleton<TripRepository>(manager.trip)
    ..registerSingleton<ChatRepository>(manager.chat)
    ..registerSingleton<NotificationsRepository>(manager.notifications)
    ..registerSingleton<EmergencyRepository>(manager.emergency)
    ..registerSingleton<PaymentRepository>(manager.payment)
    ..registerSingleton<BoardingRepository>(manager.boarding);

  // 6. Launch App
  final authBloc = AuthBloc(authRepository: manager.auth);
  final appRouter = AppRouter(authBloc: authBloc);

  await $.pumpWidgetAndSettle(SayrApp(router: appRouter, authBloc: authBloc));

  // 7. Handle Splash Screen -> Onboarding auto-navigation
  // Splash animation is 1200ms
  await $.pump(const Duration(seconds: 2));

  // Skip onboarding if visible
  if ($('تخطي').exists) {
    await $('تخطي').tap();
  }

  return manager;
}
