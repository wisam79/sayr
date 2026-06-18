import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/locale_cubit.dart';
import 'package:sayr_mobile/core/offline_sync_service.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/core/services/osrm_service.dart';
import 'package:sayr_mobile/core/theme_cubit.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_mobile/routing/app_router.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:sayr_mobile/core/services/driver_location_service.dart';

// Mock services
class MockBleBeaconService extends Mock implements BleBeaconService {}

class MockDriverLocationService extends Mock implements DriverLocationService {}

class FakeTrackingBloc extends Fake implements TrackingBloc {}

class MockOsrmService extends Mock implements OsrmService {}

class MockOfflineSyncService extends Mock implements OfflineSyncService {}

// Mock classes using mocktail
class MockAuthRepository extends Mock implements AuthRepository {}

class MockRouteRepository extends Mock implements RouteRepository {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class MockTripRepository extends Mock implements TripRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockEmergencyRepository extends Mock implements EmergencyRepository {}

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockBoardingRepository extends Mock implements BoardingRepository {}

class TestLocaleCubit extends LocaleCubit {
  @override
  Future<void> load() async {
    // No-op
  }
  @override
  Future<void> setLocale(Locale locale) async {
    emit(locale);
  }
}

class TestThemeCubit extends ThemeCubit {
  @override
  Future<void> load() async {
    // No-op
  }
  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    emit(themeMode);
  }
}

Widget buildTestApp(AppRouter router) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(
          authRepository: sl<AuthRepository>(),
        )..add(const AuthCheckRequested()),
      ),
      BlocProvider<RoutesBloc>(
        create: (_) => RoutesBloc(
          routeRepository: sl<RouteRepository>(),
        ),
      ),
      BlocProvider<SubscriptionsBloc>(
        create: (_) => SubscriptionsBloc(
          subscriptionRepository: sl<SubscriptionRepository>(),
        ),
      ),
      BlocProvider<TrackingBloc>(
        create: (_) => TrackingBloc(
          tripRepository: sl<TripRepository>(),
          authRepository: sl<AuthRepository>(),
        ),
      ),
      BlocProvider<ChatBloc>(
        create: (_) => ChatBloc(
          chatRepository: sl<ChatRepository>(),
        ),
      ),
      BlocProvider<ChatListBloc>(
        create: (_) => ChatListBloc(
          chatRepository: sl<ChatRepository>(),
        ),
      ),
      BlocProvider<NotificationsBloc>(
        create: (_) => NotificationsBloc(
          notificationsRepository: sl<NotificationsRepository>(),
        ),
      ),
      BlocProvider<EmergencyBloc>(
        create: (_) => EmergencyBloc(
          emergencyRepository: sl<EmergencyRepository>(),
        ),
      ),
      BlocProvider<PaymentBloc>(
        create: (_) => PaymentBloc(
          paymentRepository: sl<PaymentRepository>(),
        ),
      ),
      BlocProvider<LocaleCubit>(
        create: (_) => TestLocaleCubit()..load(),
      ),
      BlocProvider<ThemeCubit>(
        create: (_) => TestThemeCubit()..load(),
      ),
    ],
    child: BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        final uri = router.config.routerDelegate.currentConfiguration.uri;
        final path = uri.path;
        final isPublic = AppRouter.publicPaths.contains(path);
        final isAuthEntry = AppRouter.authEntryPaths.contains(path);

        if (state is AuthAuthenticated) {
          if (isAuthEntry) {
            router.config.go('/');
          }
        } else if (state is AuthUnauthenticated && !isPublic) {
          router.config.go('/login');
        } else if (state is AuthProfileIncomplete) {
          router.config.go('/complete-profile');
        }
      },
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          final isRtl = locale.languageCode == 'ar';
          return MaterialApp.router(
            title: 'Sayr',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            locale: locale,
            builder: (context, child) {
              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            routerConfig: router.config,
          );
        },
      ),
    ),
  );
}

void main() {
  group('Sayr E2E Integrated Test', () {
    late Directory tempDir;

    setUpAll(() {
      registerFallbackValue(const TripId('fake-trip-id'));
      registerFallbackValue(const RouteId('fake-route-id'));
      registerFallbackValue(const UserId('fake-user-id'));
      registerFallbackValue(
        const Coordinates(latitude: 33.3128, longitude: 44.3615),
      );
      registerFallbackValue(DateTime(2026));
      registerFallbackValue(MockTripRepository());
      registerFallbackValue(Logger());
      registerFallbackValue(FakeTrackingBloc());

      tempDir = Directory.systemTemp.createTempSync('hive_tests');
      Hive.init(tempDir.path);
    });

    tearDownAll(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    late MockAuthRepository mockAuthRepository;
    late MockRouteRepository mockRouteRepository;
    late MockSubscriptionRepository mockSubscriptionRepository;
    late MockTripRepository mockTripRepository;
    late MockChatRepository mockChatRepository;
    late MockNotificationsRepository mockNotificationsRepository;
    late MockEmergencyRepository mockEmergencyRepository;
    late MockPaymentRepository mockPaymentRepository;
    late MockBoardingRepository mockBoardingRepository;

    const testStudent = User(
      id: UserId('test-student-id'),
      email: 'test@student.iq',
      role: UserRole.student,
      fullName: 'محمد علي',
      phone: '+9647701234567',
      institutionId: InstitutionId('inst-1'),
      isVerified: true,
    );

    const testDriver = User(
      id: UserId('driver-123'),
      email: 'test@driver.iq',
      role: UserRole.driver,
      fullName: 'أحمد السائق',
      phone: '+9647701234568',
      institutionId: InstitutionId('inst-1'),
      isVerified: true,
    );

    const testRoute = Route(
      id: RouteId('route-test-123'),
      driverId: DriverId('driver-123'),
      title: 'خط جامعة بغداد - الجادرية',
      startLocation: 'المنصور',
      endLocation: 'الجادرية',
      price: Money(5000),
      capacity: 25,
      availableSeats: 12,
      isActive: true,
      institutionId: InstitutionId('inst-1'),
    );

    final testSubscription = Subscription(
      id: const SubscriptionId('sub-test-456'),
      studentId: const UserId('test-student-id'),
      routeId: const RouteId('route-test-123'),
      status: SubscriptionStatus.active,
      startDate: DateTime(2026),
      endDate: DateTime(2026, 12, 31),
    );

    final testTrip = Trip(
      id: const TripId('trip-test-456'),
      routeId: const RouteId('route-test-123'),
      driverId: const DriverId('driver-123'),
      status: TripStatus.inTransit,
      scheduledAt: DateTime(2026, 6, 9, 12),
      lastLocation: const Coordinates(latitude: 33.3128, longitude: 44.3615),
    );

    final testBoardingRecord = BoardingRecord(
      id: const BoardingId('rec-123'),
      tripId: const TripId('trip-test-456'),
      subscriptionId: const SubscriptionId('sub-test-456'),
      studentId: const UserId('test-student-id'),
      studentName: 'محمد علي',
      boardedAt: DateTime(2026, 6, 9, 12, 10),
    );

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockRouteRepository = MockRouteRepository();
      mockSubscriptionRepository = MockSubscriptionRepository();
      mockTripRepository = MockTripRepository();
      mockChatRepository = MockChatRepository();
      mockNotificationsRepository = MockNotificationsRepository();
      mockEmergencyRepository = MockEmergencyRepository();
      mockPaymentRepository = MockPaymentRepository();
      mockBoardingRepository = MockBoardingRepository();

      // Configure default stubs for startup
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => null);
      when(() => mockAuthRepository.authStateChanges)
          .thenAnswer((_) => const Stream.empty());

      when(() => mockRouteRepository.getActiveRoutes())
          .thenAnswer((_) async => const Right([testRoute]));
      when(() => mockRouteRepository.search(any()))
          .thenAnswer((_) async => const Right([testRoute]));

      when(() => mockSubscriptionRepository.getMySubscriptions())
          .thenAnswer((_) async => Right([testSubscription]));
      when(() => mockSubscriptionRepository.getActiveSubscriptions())
          .thenAnswer((_) async => Right([testSubscription]));

      when(() => mockTripRepository.getActiveTrips())
          .thenAnswer((_) async => Right([testTrip]));
      when(() => mockTripRepository.watchTrip(any()))
          .thenAnswer((_) => Stream.value(testTrip));
      when(
        () => mockTripRepository.updateBleOtp(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer(
        (_) async => const Right(unit),
      );

      when(() => mockChatRepository.getMyConversations())
          .thenAnswer((_) async => const Right([]));
      when(() => mockChatRepository.watchMyConversations())
          .thenAnswer((_) => Stream.value([]));
      when(() => mockChatRepository.getUnreadCount())
          .thenAnswer((_) async => const Right(0));

      when(
        () => mockNotificationsRepository.getMyNotifications(
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right([]));
      when(() => mockNotificationsRepository.watchMyNotifications())
          .thenAnswer((_) => Stream.value([]));
      when(() => mockNotificationsRepository.getUnreadCount())
          .thenAnswer((_) async => const Right(0));
      when(
        () => mockNotificationsRepository.registerPushToken(
          fcmToken: any(named: 'fcmToken'),
          platform: any(named: 'platform'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async => const Right(unit),
      );

      // Default stubs for boarding
      when(() => mockBoardingRepository.getActiveTripForSubscription())
          .thenAnswer(
        (_) async => const Right(TripId('trip-test-456')),
      );
      when(() => mockBoardingRepository.generateBoardingToken(any()))
          .thenAnswer(
        (_) async => Right(
          BoardingTokenResult(
            token: 'fake-student-boarding-qr-token',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
        ),
      );
      when(
        () => mockBoardingRepository.validateBoarding(
          token: any(named: 'token'),
          tripId: any(named: 'tripId'),
          driverLocation: any(named: 'driverLocation'),
        ),
      ).thenAnswer(
        (_) async => Right(testBoardingRecord),
      );
      when(() => mockBoardingRepository.getTripPassengers(any()))
          .thenAnswer((_) async => Right([testBoardingRecord]));
      when(() => mockBoardingRepository.watchTripPassengers(any()))
          .thenAnswer((_) => Stream.value([testBoardingRecord]));
      when(
        () => mockBoardingRepository.validateBoardingViaProximity(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
          studentLocation: any(named: 'studentLocation'),
        ),
      ).thenAnswer(
        (_) async => Right(testBoardingRecord),
      );

      when(() => mockPaymentRepository.getPendingPayments())
          .thenAnswer((_) async => const Right(<PaymentInfo>[]));

      when(() => mockEmergencyRepository.getActiveReport())
          .thenAnswer((_) async => const Right(null));
    });

    tearDown(() async {
      await sl.reset();
    });

    void setupGlobalMocks() {
      final mockBle = MockBleBeaconService();
      final mockLocation = MockDriverLocationService();
      final mockOsrm = MockOsrmService();
      final mockOfflineSync = MockOfflineSyncService();
      final talker = Talker();
      final router = AppRouter();

      when(mockOfflineSync.start).thenAnswer((_) {});
      when(mockOfflineSync.stop).thenAnswer((_) {});
      when(mockBle.startScanning).thenAnswer((_) async => true);
      when(mockBle.stopScanning).thenAnswer((_) async {});
      when(
        () => mockBle.startAdvertising(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async {});
      when(mockBle.stopAdvertising).thenAnswer((_) async {});
      when(
        () => mockBle.startRotatingOtpAdvertising(
          tripId: any(named: 'tripId'),
          tripRepository: any(named: 'tripRepository'),
          logger: any(named: 'logger'),
        ),
      ).thenAnswer((_) {});
      when(mockBle.stopRotatingOtpAdvertising).thenAnswer((_) {});
      when(() => mockBle.discoveredTrips).thenAnswer(
        (_) => const Stream.empty(),
      );

      when(() => mockLocation.stopTracking()).thenAnswer((_) async {});
      when(
        () => mockLocation.startTracking(
          tripId: any(named: 'tripId'),
          trackingBloc: any(named: 'trackingBloc'),
        ),
      ).thenAnswer((_) async {});

      sl
        ..allowReassignment = true
        ..registerSingleton<Talker>(talker)
        ..registerSingleton<AppRouter>(router)
        ..registerSingleton<BleBeaconService>(mockBle)
        ..registerSingleton<DriverLocationService>(mockLocation)
        ..registerSingleton<OsrmService>(mockOsrm)
        ..registerSingleton<OfflineSyncService>(mockOfflineSync)
        ..registerSingleton<AuthRepository>(mockAuthRepository)
        ..registerSingleton<RouteRepository>(mockRouteRepository)
        ..registerSingleton<SubscriptionRepository>(mockSubscriptionRepository)
        ..registerSingleton<TripRepository>(mockTripRepository)
        ..registerSingleton<ChatRepository>(mockChatRepository)
        ..registerSingleton<NotificationsRepository>(
          mockNotificationsRepository,
        )
        ..registerSingleton<EmergencyRepository>(mockEmergencyRepository)
        ..registerSingleton<PaymentRepository>(mockPaymentRepository)
        ..registerSingleton<BoardingRepository>(mockBoardingRepository);
    }

    testWidgets('simple debug test', (tester) async {
      debugPrint('DEBUG: Test is running!');
      expect(true, true);
    });

    testWidgets('auth flow: onboarding → login validation → successful login',
        (tester) async {
      setupGlobalMocks();
      runApp(buildTestApp(sl<AppRouter>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.safePumpAndSettle();

      // Skip onboarding
      final skipButton = find.text('تخطي');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);
      await tester.safePumpAndSettle();

      // Login page validation
      expect(find.text('تسجيل الدخول'), findsWidgets);
      final loginButton = find.widgetWithText(PrimaryButton, 'تسجيل الدخول');
      expect(loginButton, findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.safePumpAndSettle();

      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.safePumpAndSettle();
      await tester.ensureVisible(loginButton);
      await tester.safePumpAndSettle();

      await tester.tap(loginButton);
      await tester.safePumpAndSettle();
      expect(find.text('بريد غير صحيح'), findsOneWidget);

      // Successful auth
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@student.iq',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPass123!');
      await tester.safePumpAndSettle();

      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.safePumpAndSettle();
      await tester.ensureVisible(loginButton);
      await tester.safePumpAndSettle();

      when(
        () => mockAuthRepository.signInWithPassword(
          email: 'test@student.iq',
          password: 'TestPass123!',
        ),
      ).thenAnswer(
        (_) async => const Right(testStudent),
      );
      when(() => mockAuthRepository.currentUser).thenReturn(testStudent);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testStudent);

      await tester.tap(loginButton);
      await tester.safePumpAndSettle(const Duration(seconds: 1));

      expect(find.textContaining('مرحباً، محمد'), findsOneWidget);
    });

    testWidgets('student home: tabs, routes, subscriptions', (tester) async {
      when(() => mockAuthRepository.currentUser).thenReturn(testStudent);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testStudent);

      setupGlobalMocks();
      runApp(buildTestApp(sl<AppRouter>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.safePumpAndSettle();

      expect(find.textContaining('مرحباً، محمد'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);

      // Navigate to Routes Tab (Index 1)
      await tester.tap(find.byIcon(Icons.route_outlined));
      await tester.safePumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('خط جامعة بغداد - الجادرية'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'بغداد');
      await tester.safePumpAndSettle();

      // Navigate to Active Trips Tab (Index 2)
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.safePumpAndSettle();
      expect(find.text('قيد السير'), findsOneWidget);

      // Navigate to Subscriptions Tab (Index 3)
      await tester.tap(find.byIcon(Icons.local_activity_outlined));
      await tester.safePumpAndSettle();
      expect(find.textContaining('ينتهي:'), findsOneWidget);

      // Navigate to Profile Tab (Index 4)
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.safePumpAndSettle();
      expect(find.text('محمد علي'), findsOneWidget);
      expect(find.text('test@student.iq'), findsOneWidget);
    });

    testWidgets('language switch: English ↔ Arabic and Student Logout',
        (tester) async {
      when(() => mockAuthRepository.currentUser).thenReturn(testStudent);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testStudent);

      setupGlobalMocks();
      runApp(buildTestApp(sl<AppRouter>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.safePumpAndSettle();

      // Navigate to Profile tab
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.safePumpAndSettle();

      // English localization
      final englishSegment = find.text('English');
      expect(englishSegment, findsOneWidget);
      await tester.ensureVisible(englishSegment);
      await tester.safePumpAndSettle();
      await tester.tap(englishSegment);
      await tester.safePumpAndSettle();
      expect(find.text('Language'), findsOneWidget);

      // Arabic localization
      final arabicSegment = find.text('العربية');
      await tester.ensureVisible(arabicSegment);
      await tester.safePumpAndSettle();
      await tester.tap(arabicSegment);
      await tester.safePumpAndSettle();
      expect(find.text('اللغة'), findsOneWidget);

      // Logout flow
      final logoutTile = find.text('تسجيل الخروج');
      expect(logoutTile, findsOneWidget);
      await tester.ensureVisible(logoutTile);
      await tester.safePumpAndSettle();
      await tester.tap(logoutTile);
      await tester.safePumpAndSettle();

      expect(find.text('هل أنت متأكد من تسجيل الخروج؟'), findsOneWidget);

      final cancelButton = find.text('إلغاء');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.safePumpAndSettle();
      expect(find.text('تسجيل الخروج'), findsOneWidget);

      // Tap logout again and confirm
      await tester.tap(logoutTile);
      await tester.safePumpAndSettle();

      when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => null);

      final confirmLogoutButton =
          find.widgetWithText(FilledButton, 'تسجيل الخروج');
      expect(confirmLogoutButton, findsOneWidget);
      await tester.tap(confirmLogoutButton);
      await tester.safePumpAndSettle(const Duration(seconds: 1));

      expect(
        find.text('أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة'),
        findsOneWidget,
      );
    });

    testWidgets(
        'driver flow: login → create trip → boarding scanner → student boarding QR → driver logout',
        (tester) async {
      setupGlobalMocks();
      runApp(buildTestApp(sl<AppRouter>()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.safePumpAndSettle();

      // Skip onboarding
      final skipButton = find.text('تخطي');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);
      await tester.safePumpAndSettle();

      // Input driver credentials
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@driver.iq',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPass123!');
      await tester.safePumpAndSettle();

      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.safePumpAndSettle();
      final loginButton = find.widgetWithText(PrimaryButton, 'تسجيل الدخول');
      await tester.ensureVisible(loginButton);
      await tester.safePumpAndSettle();

      when(
        () => mockAuthRepository.signInWithPassword(
          email: 'test@driver.iq',
          password: 'TestPass123!',
        ),
      ).thenAnswer(
        (_) async => const Right(testDriver),
      );
      when(() => mockAuthRepository.currentUser).thenReturn(testDriver);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testDriver);

      await tester.tap(loginButton);
      await tester.safePumpAndSettle(const Duration(seconds: 1));

      // Verify driver home
      expect(find.textContaining('مرحباً، أحمد'), findsOneWidget);

      final activeTripsCard = find.text('رحلاتي النشطة');
      expect(activeTripsCard, findsOneWidget);
      await tester.tap(activeTripsCard);
      await tester.safePumpAndSettle();

      expect(find.text('قيد السير'), findsWidgets);

      // Navigate to controls
      sl<AppRouter>().config.go('/driver-trip/trip-test-456');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('تحكم بالرحلة'), findsOneWidget);
      expect(find.text('قيد السير'), findsWidgets);
      expect(find.text('أكمل'), findsOneWidget);

      // Navigate to boarding scanner page
      sl<AppRouter>().config.go('/driver-trip/trip-test-456/boarding');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('مسح صعود الركاب'), findsOneWidget);
      expect(find.text('محمد علي'), findsOneWidget);

      // Student boarding QR page
      when(() => mockAuthRepository.currentUser).thenReturn(testStudent);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testStudent);

      sl<AppRouter>().config.go('/boarding');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('الصعود إلى الحافلة'), findsOneWidget);
      expect(find.text('اعرض هذا الرمز على السائق عند الصعود'), findsOneWidget);
      expect(find.byType(PrettyQrView), findsOneWidget);

      // Driver Logout Flow
      when(() => mockAuthRepository.currentUser).thenReturn(testDriver);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testDriver);

      sl<AppRouter>().config.go('/');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.safePumpAndSettle();

      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.safePumpAndSettle();

      final driverLogoutTile = find.text('تسجيل الخروج');
      expect(driverLogoutTile, findsOneWidget);
      await tester.ensureVisible(driverLogoutTile);
      await tester.safePumpAndSettle();
      await tester.tap(driverLogoutTile);
      await tester.safePumpAndSettle();

      when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => null);

      final confirmDriverLogoutButton =
          find.widgetWithText(FilledButton, 'تسجيل الخروج');
      expect(confirmDriverLogoutButton, findsOneWidget);
      await tester.tap(confirmDriverLogoutButton);
      await tester.safePumpAndSettle(const Duration(seconds: 1));

      expect(
        find.text('أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة'),
        findsOneWidget,
      );
    });
  });
}

extension SafePumpAndSettle on WidgetTester {
  Future<void> safePumpAndSettle([Duration? duration]) async {
    for (var i = 0; i < 20; i++) {
      await pump(duration ?? const Duration(milliseconds: 100));
    }
  }
}
