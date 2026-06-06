import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/trip_details_cubit.dart';

class MockRouteRepository extends Mock implements RouteRepository {}
class MockTripRepository extends Mock implements TripRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
    registerFallbackValue(const DriverId('fallback'));
    registerFallbackValue(const TripId('fallback'));
    registerFallbackValue(const UserId('fallback'));
  });

  late MockRouteRepository mockRouteRepo;
  late MockTripRepository mockTripRepo;
  late TripDetailsCubit cubit;

  const testRoute = Route(
    id: RouteId('route-1'),
    driverId: DriverId('driver-1'),
    title: 'Test Route',
    startLocation: 'Start',
    endLocation: 'End',
    price: Money(1000),
    capacity: 30,
    availableSeats: 25,
    isActive: true,
  );

  const testDriver = Driver(
    id: DriverId('driver-1'),
    userId: UserId('user-1'),
    vehicleModel: 'KIA',
    vehiclePlate: 'A123',
    capacity: 10,
    rating: 4.8,
  );

  const testDriverProfile = User(
    id: UserId('user-1'),
    email: 'driver@sayr.app',
    role: UserRole.driver,
    fullName: 'Driver Name',
    phone: '07901234567',
  );

  final testRating = Rating(
    id: const RatingId('rate-1'),
    tripId: const TripId('trip-1'),
    studentId: const UserId('student-1'),
    driverId: const DriverId('driver-1'),
    rating: 5,
    createdAt: DateTime.parse('2026-06-04T08:00:00Z'),
  );

  setUp(() {
    mockRouteRepo = MockRouteRepository();
    mockTripRepo = MockTripRepository();
    cubit = TripDetailsCubit(
      routeRepository: mockRouteRepo,
      tripRepository: mockTripRepo,
    );
  });

  tearDown(() => cubit.close());

  test('initial state is TripDetailsInitial', () {
    expect(cubit.state, isA<TripDetailsInitial>());
  });

  blocTest<TripDetailsCubit, TripDetailsState>(
    'loadTripDetails emits Loading then Loaded on success',
    build: () {
      when(() => mockRouteRepo.getById(any())).thenAnswer(
        (_) async => const Right<Failure, Route>(testRoute),
      );
      when(() => mockTripRepo.getDriverById(any())).thenAnswer(
        (_) async => const Right<Failure, Driver>(testDriver),
      );
      when(() => mockTripRepo.getDriverProfile(any())).thenAnswer(
        (_) async => const Right<Failure, User>(testDriverProfile),
      );
      when(() => mockTripRepo.getTripRating(any())).thenAnswer(
        (_) async => Right<Failure, Rating?>(testRating),
      );
      return TripDetailsCubit(
        routeRepository: mockRouteRepo,
        tripRepository: mockTripRepo,
      );
    },
    act: (cubit) => cubit.loadTripDetails(
      routeId: const RouteId('route-1'),
      driverId: const DriverId('driver-1'),
      tripId: const TripId('trip-1'),
    ),
    expect: () => [
      isA<TripDetailsLoading>(),
      isA<TripDetailsLoaded>(),
    ],
  );

  blocTest<TripDetailsCubit, TripDetailsState>(
    'loadTripDetails emits Loading then Error on route load failure',
    build: () {
      when(() => mockRouteRepo.getById(any())).thenAnswer(
        (_) async => const Left<Failure, Route>(
          ServerFailure(message: 'oops'),
        ),
      );
      when(() => mockTripRepo.getDriverById(any())).thenAnswer(
        (_) async => const Right<Failure, Driver>(testDriver),
      );
      when(() => mockTripRepo.getTripRating(any())).thenAnswer(
        (_) async => const Right<Failure, Rating?>(null),
      );
      return TripDetailsCubit(
        routeRepository: mockRouteRepo,
        tripRepository: mockTripRepo,
      );
    },
    act: (cubit) => cubit.loadTripDetails(
      routeId: const RouteId('route-1'),
      driverId: const DriverId('driver-1'),
      tripId: const TripId('trip-1'),
    ),
    expect: () => [
      isA<TripDetailsLoading>(),
      isA<TripDetailsError>(),
    ],
  );

  blocTest<TripDetailsCubit, TripDetailsState>(
    'submitTripRating submits and updates loaded rating on success',
    build: () {
      return TripDetailsCubit(
        routeRepository: mockRouteRepo,
        tripRepository: mockTripRepo,
      );
    },
    seed: () => const TripDetailsLoaded(
      route: testRoute,
      driver: testDriver,
    ),
    act: (cubit) {
      when(
        () => mockTripRepo.submitRating(
          tripId: any(named: 'tripId'),
          driverId: any(named: 'driverId'),
          rating: any(named: 'rating'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => Right<Failure, Rating>(testRating));
      return cubit.submitTripRating(
        tripId: const TripId('trip-1'),
        driverId: const DriverId('driver-1'),
        rating: 5,
        comment: 'Great',
      );
    },
    expect: () => [
      isA<TripDetailsLoaded>().having(
        (s) => s.tripRating,
        'tripRating',
        testRating,
      ),
    ],
  );
}
