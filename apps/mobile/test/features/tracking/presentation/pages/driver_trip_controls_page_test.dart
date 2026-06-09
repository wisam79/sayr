import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/driver_trip_controls_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockTrackingBloc extends MockBloc<TrackingEvent, TrackingState>
    implements TrackingBloc {}

class MockEmergencyBloc extends MockBloc<EmergencyEvent, EmergencyState>
    implements EmergencyBloc {}

class MockBleBeaconService extends Mock implements BleBeaconService {}

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTrackingBloc mockTrackingBloc;
  late MockEmergencyBloc mockEmergencyBloc;
  late MockBleBeaconService mockBle;
  late MockTripRepository mockTripRepo;

  setUpAll(() {
    registerFallbackValue(const TrackingWatchTrip(tripId: TripId('trip-1')));
    registerFallbackValue(const TrackingDriverArrive(tripId: TripId('trip-1')));
    registerFallbackValue(const TrackingDriverCancel(tripId: TripId('trip-1')));
    registerFallbackValue(const TripId('fallback'));
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockTrackingBloc = MockTrackingBloc();
    mockEmergencyBloc = MockEmergencyBloc();
    mockBle = MockBleBeaconService();
    mockTripRepo = MockTripRepository();

    when(() => mockEmergencyBloc.state).thenReturn(const EmergencyIdle());
    when(() => mockBle.stopAdvertising()).thenAnswer((_) async {});
    when(
      () => mockBle.startAdvertising(
        tripId: any(named: 'tripId'),
        otp: any(named: 'otp'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockTripRepo.updateBleOtp(
        tripId: any(named: 'tripId'),
        otp: any(named: 'otp'),
        expiresAt: any(named: 'expiresAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    GetIt.I.registerFactory<BleBeaconService>(() => mockBle);
    GetIt.I.registerFactory<TripRepository>(() => mockTripRepo);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  final testTrip = Trip(
    id: const TripId('trip-1'),
    routeId: const RouteId('route-1'),
    driverId: const DriverId('driver-1'),
    status: TripStatus.scheduled,
    scheduledAt: DateTime.now().add(const Duration(hours: 1)),
  );

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<TrackingBloc>.value(value: mockTrackingBloc),
          BlocProvider<EmergencyBloc>.value(value: mockEmergencyBloc),
        ],
        child: DriverTripControlsPage(
          tripId: const TripId('trip-1'),
          trackingBloc: mockTrackingBloc,
        ),
      ),
    );
  }

  testWidgets(
    'renders SwipeButton and Cancel button when active',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockTrackingBloc.state).thenReturn(
        TrackingDriverActive(
          trip: testTrip,
          validActions: const [TripEvent.arrive, TripEvent.cancel],
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Check progressive swipe button is rendered
      expect(find.byType(SwipeButton), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);

      // Check cancel text button is rendered
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    },
  );

  testWidgets(
    'swiping the SwipeButton triggers arrive event',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockTrackingBloc.state).thenReturn(
        TrackingDriverActive(
          trip: testTrip,
          validActions: const [TripEvent.arrive],
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final swipeButton = find.byType(SwipeButton);
      expect(swipeButton, findsOneWidget);

      final thumb = find.byIcon(Icons.location_on);
      expect(thumb, findsOneWidget);

      // Swipe the button thumb
      await tester.drag(thumb, const Offset(300, 0), warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(
        () => mockTrackingBloc.add(
          any(
            that: isA<TrackingDriverArrive>().having(
              (e) => e.tripId,
              'tripId',
              const TripId('trip-1'),
            ),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'clicking cancel button and selecting No dismisses dialog '
    'and does not trigger cancel event',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockTrackingBloc.state).thenReturn(
        TrackingDriverActive(
          trip: testTrip,
          validActions: const [TripEvent.cancel],
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.text('Cancel Trip?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to cancel this trip?'),
        findsOneWidget,
      );

      // Tap No, should dismiss dialog and not call cancel
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel Trip?'), findsNothing);
      verifyNever(
        () => mockTrackingBloc.add(
          any(
            that: isA<TrackingDriverCancel>(),
          ),
        ),
      );
    },
  );

  testWidgets(
    'clicking cancel button and selecting Yes dismisses dialog '
    'and triggers cancel event',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockTrackingBloc.state).thenReturn(
        TrackingDriverActive(
          trip: testTrip,
          validActions: const [TripEvent.cancel],
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.text('Cancel Trip?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to cancel this trip?'),
        findsOneWidget,
      );

      // Tap Yes, should dismiss dialog and call cancel event
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Trip?'), findsNothing);
      verify(
        () => mockTrackingBloc.add(
          any(
            that: isA<TrackingDriverCancel>().having(
              (e) => e.tripId,
              'tripId',
              const TripId('trip-1'),
            ),
          ),
        ),
      ).called(1);
    },
  );
}
