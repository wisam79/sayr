import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/trip_tracking_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/map_widget.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class MockTrackingBloc extends MockBloc<TrackingEvent, TrackingState>
    implements TrackingBloc {}

class MockEmergencyBloc extends MockBloc<EmergencyEvent, EmergencyState>
    implements EmergencyBloc {}

class MockRouteRepository extends Mock implements RouteRepository {}

class MockDriverRepository extends Mock implements DriverRepository {}

class MockRatingRepository extends Mock implements RatingRepository {}

class MockRoutingService extends Mock implements RoutingService {}

void main() {
  late MockTrackingBloc mockTrackingBloc;
  late MockEmergencyBloc mockEmergencyBloc;
  late MockRouteRepository mockRouteRepo;
  late MockDriverRepository mockDriverRepo;
  late MockRatingRepository mockRatingRepo;
  late MockRoutingService mockRoutingService;

  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
    registerFallbackValue(const TripId('fallback'));
    registerFallbackValue(const DriverId('fallback'));
    registerFallbackValue(const UserId('fallback'));
    registerFallbackValue(const Coordinates(latitude: 0, longitude: 0));
  });

  setUp(() {
    GetIt.I.allowReassignment = true;
    mockTrackingBloc = MockTrackingBloc();
    mockEmergencyBloc = MockEmergencyBloc();
    mockRouteRepo = MockRouteRepository();
    mockDriverRepo = MockDriverRepository();
    mockRatingRepo = MockRatingRepository();
    mockRoutingService = MockRoutingService();

    when(() => mockRoutingService.getRoute(any(), any()))
        .thenAnswer((_) => Future.value(const Right([])));

    GetIt.I.registerSingleton<RouteRepository>(mockRouteRepo);
    GetIt.I.registerSingleton<DriverRepository>(mockDriverRepo);
    GetIt.I.registerSingleton<RatingRepository>(mockRatingRepo);
    GetIt.I.registerSingleton<RoutingService>(mockRoutingService);

    when(() => mockEmergencyBloc.state).thenReturn(const EmergencyIdle());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  final testTrip = Trip(
    id: const TripId('trip-1'),
    routeId: const RouteId('route-1'),
    driverId: const DriverId('driver-1'),
    status: TripStatus.inTransit,
    scheduledAt: DateTime(2026, 6, 9, 12),
    startedAt: DateTime(2026, 6, 9, 12, 5),
    lastLocation: const Coordinates(latitude: 33.3128, longitude: 44.3615),
    routeStartLocation:
        const Coordinates(latitude: 33.3120, longitude: 44.3610),
    routeEndLocation: const Coordinates(latitude: 33.3140, longitude: 44.3630),
  );

  const testRoute = Route(
    id: RouteId('route-1'),
    driverId: DriverId('driver-1'),
    title: 'Test Route Title',
    startLocation: 'Start Point',
    endLocation: 'End Point',
    price: Money(3000),
    capacity: 25,
    availableSeats: 10,
    isActive: true,
  );

  const testDriver = Driver(
    id: DriverId('driver-1'),
    userId: UserId('user-driver'),
    vehicleModel: 'KIA',
    vehiclePlate: '1234 A',
    capacity: 11,
    rating: 4.9,
  );

  const testDriverProfile = User(
    id: UserId('user-driver'),
    email: 'driver@sayr.app',
    role: UserRole.driver,
    fullName: 'Ahmed Driver',
    phone: '07701234567',
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<EmergencyBloc>.value(value: mockEmergencyBloc),
          BlocProvider<TrackingBloc>.value(value: mockTrackingBloc),
        ],
        child: child,
      ),
    );
  }

  testWidgets('renders loading state initially', (tester) async {
    when(() => mockTrackingBloc.state)
        .thenReturn(const TrackingState.initial());
    whenListen(
      mockTrackingBloc,
      const Stream<TrackingState>.empty(),
      initialState: const TrackingState.initial(),
    );

    await tester.pumpWidget(
      wrap(
        TripTrackingPage(
          tripId: const TripId('trip-1'),
          trackingBloc: mockTrackingBloc,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LoadingWidget), findsOneWidget);
  });

  testWidgets(
      'renders map and route details when trip watches and details load',
      (tester) async {
    when(() => mockRouteRepo.getById(any()))
        .thenAnswer((_) => Future.value(const Right(testRoute)));
    when(() => mockDriverRepo.getDriverById(any()))
        .thenAnswer((_) => Future.value(const Right(testDriver)));
    when(() => mockDriverRepo.getDriverProfile(any()))
        .thenAnswer((_) => Future.value(const Right(testDriverProfile)));
    when(() => mockRatingRepo.getTripRating(any()))
        .thenAnswer((_) => Future.value(const Right(null)));

    final targetState = TrackingTripWatching(
      trip: testTrip,
      driverLocation: testTrip.lastLocation,
    );

    when(() => mockTrackingBloc.state).thenReturn(targetState);
    whenListen(
      mockTrackingBloc,
      Stream.value(targetState),
      initialState: targetState,
    );

    await tester.pumpWidget(
      wrap(
        TripTrackingPage(
          tripId: const TripId('trip-1'),
          trackingBloc: mockTrackingBloc,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Map should be rendered
    expect(find.byType(SayrMap), findsOneWidget);

    // Location tiles should show start and end locations
    expect(find.text('Start Point'), findsOneWidget);
    expect(find.text('End Point'), findsOneWidget);

    // Driver name should be rendered
    expect(find.text('Ahmed Driver'), findsOneWidget);
  });

  testWidgets('renders error view when trip watching fails', (tester) async {
    const errorState = TrackingState.error(
      failure: ServerFailure(message: 'Connection failed'),
    );

    when(() => mockTrackingBloc.state).thenReturn(errorState);
    whenListen(
      mockTrackingBloc,
      Stream.value(errorState),
      initialState: errorState,
    );

    await tester.pumpWidget(
      wrap(
        TripTrackingPage(
          tripId: const TripId('trip-1'),
          trackingBloc: mockTrackingBloc,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.textContaining('Connection failed'), findsAtLeastNWidgets(1));

    // Advance time to allow SayrFlash's auto-dismiss timer to complete
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
