import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

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

void registerFallbackValues() {
  registerFallbackValue(const TripId('fake-trip-id'));
  registerFallbackValue(const RouteId('fake-route-id'));
  registerFallbackValue(const UserId('fake-user-id'));
  registerFallbackValue(Coordinates(latitude: 33.3128, longitude: 44.3615));
  registerFallbackValue(DateTime(2026));
}

final testStudent = User(
  id: const UserId('test-student-id'),
  email: 'test@student.iq',
  role: UserRole.student,
  fullName: 'محمد علي',
  phone: '+9647701234567',
  institutionId: const InstitutionId('inst-1'),
  isVerified: true,
);

final testDriver = User(
  id: const UserId('driver-123'),
  email: 'test@driver.iq',
  role: UserRole.driver,
  fullName: 'أحمد السائق',
  phone: '+9647701234568',
  institutionId: const InstitutionId('inst-1'),
  isVerified: true,
);

final testRoute = Route(
  id: const RouteId('route-test-123'),
  driverId: const DriverId('driver-123'),
  title: 'خط جامعة بغداد - الجادرية',
  startLocation: 'المنصور',
  endLocation: 'الجادرية',
  price: const Money(5000),
  capacity: 25,
  availableSeats: 12,
  isActive: true,
  institutionId: const InstitutionId('inst-1'),
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
  lastLocation: Coordinates(latitude: 33.3128, longitude: 44.3615),
);

final testBoardingRecord = BoardingRecord(
  id: const BoardingId('rec-123'),
  tripId: const TripId('trip-test-456'),
  subscriptionId: const SubscriptionId('sub-test-456'),
  studentId: const UserId('test-student-id'),
  studentName: 'محمد علي',
  boardedAt: DateTime(2026, 6, 9, 12, 10),
);

class MockManager {
  final auth = MockAuthRepository();
  final route = MockRouteRepository();
  final subscription = MockSubscriptionRepository();
  final trip = MockTripRepository();
  final chat = MockChatRepository();
  final notifications = MockNotificationsRepository();
  final emergency = MockEmergencyRepository();
  final payment = MockPaymentRepository();
  final boarding = MockBoardingRepository();

  void setupDefaultStubs() {
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.fetchFullProfile())
        .thenAnswer((_) async => const Right<Failure, User?>(null));
    when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());

    when(() => route.getActiveRoutes()).thenAnswer(
        (_) async => Right((routes: [testRoute], fromCache: false)));
    when(() => route.search(any())).thenAnswer((_) async => Right([testRoute]));

    when(() => subscription.getMySubscriptions())
        .thenAnswer((_) async => Right([testSubscription]));
    when(() => subscription.getActiveSubscriptions())
        .thenAnswer((_) async => Right([testSubscription]));

    when(() => trip.getActiveTrips())
        .thenAnswer((_) async => Right((trips: [testTrip], fromCache: false)));
    when(() => trip.watchTrip(any())).thenAnswer((_) => Stream.value(testTrip));
    when(() => trip.updateBleOtp(
            tripId: any(named: 'tripId'),
            otp: any(named: 'otp'),
            expiresAt: any(named: 'expiresAt')))
        .thenAnswer((_) async => const Right(unit));

    when(() => chat.getMyConversations())
        .thenAnswer((_) async => const Right([]));
    when(() => chat.watchMyConversations()).thenAnswer((_) => Stream.value([]));
    when(() => chat.getUnreadCount()).thenAnswer((_) async => const Right(0));

    when(() => notifications.getMyNotifications(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
    when(() => notifications.watchMyNotifications())
        .thenAnswer((_) => Stream.value([]));
    when(() => notifications.getUnreadCount())
        .thenAnswer((_) async => const Right(0));
    when(() => notifications.registerPushToken(
            fcmToken: any(named: 'fcmToken'),
            platform: any(named: 'platform'),
            deviceId: any(named: 'deviceId')))
        .thenAnswer((_) async => const Right(unit));

    when(() => boarding.getActiveTripForSubscription())
        .thenAnswer((_) async => const Right(TripId('trip-test-456')));
    when(() => boarding.generateBoardingToken(any())).thenAnswer(
      (_) async => Right(BoardingTokenResult(
          token: 'fake-student-boarding-qr-token',
          expiresAt: DateTime.now().add(const Duration(minutes: 5)))),
    );
    when(() => boarding.validateBoarding(
            token: any(named: 'token'),
            tripId: any(named: 'tripId'),
            driverLocation: any(named: 'driverLocation')))
        .thenAnswer((_) async => Right(testBoardingRecord));
    when(() => boarding.getTripPassengers(any()))
        .thenAnswer((_) async => Right([testBoardingRecord]));
    when(() => boarding.watchTripPassengers(any()))
        .thenAnswer((_) => Stream.value([testBoardingRecord]));
    when(() => boarding.validateBoardingViaProximity(
            tripId: any(named: 'tripId'),
            otp: any(named: 'otp'),
            studentLocation: any(named: 'studentLocation')))
        .thenAnswer((_) async => Right(testBoardingRecord));

    when(() => emergency.getActiveReport())
        .thenAnswer((_) async => const Right(null));
  }
}
