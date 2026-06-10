import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/app.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/routing/app_router.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sayr E2E Integrated Test', () {
    setUpAll(() {
      registerFallbackValue(const TripId('fake-trip-id'));
      registerFallbackValue(const RouteId('fake-route-id'));
      registerFallbackValue(const UserId('fake-user-id'));
      registerFallbackValue(
        const Coordinates(latitude: 33.3128, longitude: 44.3615),
      );
      registerFallbackValue(DateTime(2026));
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

      when(() => mockEmergencyRepository.getActiveReport())
          .thenAnswer((_) async => const Right(null));
    });

    testWidgets(
        'Full student lifecycle flow (Splash -> Onboarding -> Login Validations -> Successful Auth -> Tabs Navigation -> Language Switch -> Logout)',
        (tester) async {
      // Initialize local assets/databases
      await Hive.initFlutter();
      final box = await Hive.openBox<String>('settings_box');
      await box.clear();

      // Initialize Firebase
      try {
        await Firebase.initializeApp();
      } catch (_) {}

      // Initialize Supabase client
      try {
        await SayrSupabase.instance.init();
      } catch (_) {}

      // Run dependency injection setup
      await initDependencies();

      // Override dependencies in sl with our mocks
      sl
        ..allowReassignment = true
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

      // Launch the Application
      runApp(SayrApp(router: sl<AppRouter>()));
      await tester.pump();

      // ─── 1. Splash Screen ───
      // SplashPage will execute its entry animation and then navigate automatically to /onboarding
      // Let's pump for enough time to complete the 1200ms animation
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Diagnostics
      final currentPath =
          sl<AppRouter>().config.routerDelegate.currentConfiguration.uri.path;
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      debugPrint('E2E DIAGNOSTIC - Current path: $currentPath');
      debugPrint(
        'E2E DIAGNOSTIC - Visible texts: ${textWidgets.map((t) => t.data).toList()}',
      );

      // ─── 2. Onboarding Screen ───
      // Verify skip button is visible and tap it to skip to login
      final skipButton = find.text('تخطي');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      // ─── 3. Login Page & Form Validation ───
      // Verify login page description
      expect(find.text('تسجيل الدخول'), findsWidgets);
      expect(
        find.text('أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة'),
        findsOneWidget,
      );

      final loginButton = find.widgetWithText(PrimaryButton, 'تسجيل الدخول');
      expect(loginButton, findsOneWidget);

      // Perform validation check with invalid email format
      await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.pumpAndSettle();

      // Dismiss keyboard and scroll login button into view
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('بريد غير صحيح'), findsOneWidget);

      // ─── 4. Successful Authentication ───
      // Input valid credentials
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@student.iq',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPass123!');
      await tester.pumpAndSettle();

      // Dismiss keyboard and scroll login button into view
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();

      // Configure AuthRepository mock to succeed upon password sign-in
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

      // Tap login and wait for authentication logic to trigger
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ─── 5. Home Page & Navigation Tabs ───
      // Verify student welcome message on Home screen
      expect(find.textContaining('مرحباً، محمد'), findsOneWidget);

      // Verify active subscription check is loaded
      expect(find.text('نشط'), findsOneWidget);

      // 5.1 Navigate to Routes Tab (Index 1)
      await tester.tap(find.byIcon(Icons.directions_bus_outlined));
      await tester.pumpAndSettle();

      // Verify search input is displayed and active route title is rendered
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('خط جامعة بغداد - الجادرية'), findsOneWidget);

      // Type in the search input
      await tester.enterText(find.byType(TextField), 'بغداد');
      await tester.pumpAndSettle();

      // 5.2 Navigate to Active Trips Tab (Index 2)
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();
      expect(find.text('قيد السير'), findsOneWidget);

      // 5.3 Navigate to Subscriptions Tab (Index 3)
      await tester.tap(find.byIcon(Icons.confirmation_number_outlined));
      await tester.pumpAndSettle();
      expect(find.textContaining('ينتهي:'), findsOneWidget);

      // 5.4 Navigate to Profile Tab (Index 4)
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify user information matches test data
      expect(find.text('محمد علي'), findsOneWidget);
      expect(find.text('test@student.iq'), findsOneWidget);

      // ─── 6. Language Localization Switching ───
      // Tap the Language Tile to switch the locale from Arabic to English
      final languageTile = find.text('اللغة');
      expect(languageTile, findsOneWidget);
      await tester.ensureVisible(languageTile);
      await tester.pumpAndSettle();
      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // Verify English language localizations are successfully loaded
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Switch back to Arabic to continue flow
      final engLanguageTile = find.text('Language');
      await tester.ensureVisible(engLanguageTile);
      await tester.pumpAndSettle();
      await tester.tap(engLanguageTile);
      await tester.pumpAndSettle();
      expect(find.text('اللغة'), findsOneWidget);

      // ─── 7. Logout Flow ───
      // Tap logout tile
      final logoutTile = find.text('تسجيل الخروج');
      expect(logoutTile, findsOneWidget);
      await tester.ensureVisible(logoutTile);
      await tester.pumpAndSettle();
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      // Verify confirmation dialog shows up
      expect(find.text('هل أنت متأكد من تسجيل الخروج؟'), findsOneWidget);

      // Tap Cancel in the dialog first to make sure it functions correctly
      final cancelButton = find.text('إلغاء');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // User should stay on the profile screen
      expect(find.text('تسجيل الخروج'), findsOneWidget);

      // Tap logout again and choose confirm
      final logoutTileAgain = find.text('تسجيل الخروج');
      await tester.ensureVisible(logoutTileAgain);
      await tester.pumpAndSettle();
      await tester.tap(logoutTileAgain);
      await tester.pumpAndSettle();

      // Stub AuthRepository to clear session
      when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => null);

      final confirmLogoutButton =
          find.widgetWithText(FilledButton, 'تسجيل الخروج');
      expect(confirmLogoutButton, findsOneWidget);
      await tester.tap(confirmLogoutButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ─── 8. Verification ───
      // The app should route back to the LoginPage successfully
      expect(
        find.text('أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة'),
        findsOneWidget,
      );

      // ─── 9. Driver Login & Authentication ───
      // Input driver credentials
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@driver.iq',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPass123!');
      await tester.pumpAndSettle();

      // Dismiss keyboard and scroll login button into view
      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();

      // Configure AuthRepository mock to succeed upon password sign-in for driver
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

      // Tap login and wait for authentication logic to trigger
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ─── 10. Driver Home Page & Navigation ───
      // Verify driver welcome message on Home screen
      expect(find.textContaining('مرحباً، أحمد'), findsOneWidget);

      // Tap My Active Trips card to open active trips list
      final activeTripsCard = find.text('رحلاتي النشطة');
      expect(activeTripsCard, findsOneWidget);
      await tester.tap(activeTripsCard);
      await tester.pumpAndSettle();

      // Verify the active trip is rendered by checking its status
      expect(find.text('قيد السير'), findsWidgets);

      // Tap trip card to navigate to DriverTripControlsPage
      await tester.tap(find.text('قيد السير').first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // ─── 11. Driver Trip Controls Page ───
      // Verify trip control title and status
      expect(find.text('تحكم بالرحلة'), findsOneWidget);
      expect(find.text('قيد السير'), findsWidgets);

      // Verify completion Swipe button is available
      final completeSwipeButton = find.text('أكمل');
      expect(completeSwipeButton, findsOneWidget);

      // ─── 12. Driver Boarding Scanner Page ───
      // Route directly to boarding scanner to bypass physical camera scanning logic
      sl<AppRouter>().config.go('/driver-trip/trip-test-456/boarding');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify scanner page is shown and displays the passenger list
      expect(find.text('مسح رمز الصعود'), findsOneWidget);
      expect(find.text('محمد علي'), findsOneWidget);

      // ─── 13. Student Boarding QR Page ───
      // Stub AuthRepository back to testStudent to test the student QR page
      when(() => mockAuthRepository.currentUser).thenReturn(testStudent);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testStudent);

      // Route directly to student boarding QR page
      sl<AppRouter>().config.go('/boarding');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify student boarding page loads
      expect(find.text('الصعود إلى الحافلة'), findsOneWidget);
      expect(find.text('اعرض هذا الرمز على السائق عند الصعود'), findsOneWidget);
      expect(find.byType(PrettyQrView), findsOneWidget);

      // ─── 14. Driver Logout Flow ───
      // Switch back to testDriver to perform driver logout
      when(() => mockAuthRepository.currentUser).thenReturn(testDriver);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => testDriver);

      // Navigate back home to select profile tab
      sl<AppRouter>().config.go('/');
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Navigate to Profile tab (Index 2 for driver)
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Tap logout tile
      final driverLogoutTile = find.text('تسجيل الخروج');
      expect(driverLogoutTile, findsOneWidget);
      await tester.ensureVisible(driverLogoutTile);
      await tester.pumpAndSettle();
      await tester.tap(driverLogoutTile);
      await tester.pumpAndSettle();

      // Confirm logout in dialog
      when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});
      when(() => mockAuthRepository.currentUser).thenReturn(null);
      when(() => mockAuthRepository.fetchFullProfile())
          .thenAnswer((_) async => null);

      final confirmDriverLogoutButton =
          find.widgetWithText(FilledButton, 'تسجيل الخروج');
      expect(confirmDriverLogoutButton, findsOneWidget);
      await tester.tap(confirmDriverLogoutButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify redirection back to login
      expect(
        find.text('أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة'),
        findsOneWidget,
      );
    });
  });
}
