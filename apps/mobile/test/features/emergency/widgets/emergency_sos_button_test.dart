import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_state.dart';
import 'package:sayr_mobile/features/emergency/presentation/widgets/emergency_sos_button.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class MockEmergencyBloc extends MockBloc<EmergencyEvent, EmergencyState>
    implements EmergencyBloc {}

void main() {
  late MockEmergencyBloc mockEmergencyBloc;
  const channel = MethodChannel('flutter.baseflow.com/geolocator');

  setUpAll(() {
    registerFallbackValue(const EmergencyCancelled());
    registerFallbackValue(const EmergencyReset());
    registerFallbackValue(
      const EmergencyTriggered(
        tripId: TripId('trip-1'),
        routeId: RouteId('route-1'),
        location: Coordinates(latitude: 33.3, longitude: 44.3),
      ),
    );
  });

  setUp(() {
    mockEmergencyBloc = MockEmergencyBloc();

    // Mock Geolocator channel responses
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'checkPermission') {
        return 3; // LocationPermission.always
      } else if (methodCall.method == 'getCurrentPosition') {
        return {
          'latitude': 33.3,
          'longitude': 44.3,
          'timestamp': 0,
          'accuracy': 1.0,
          'altitude': 0.0,
          'heading': 0.0,
          'speed': 0.0,
          'speed_accuracy': 0.0,
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: Scaffold(
        body: BlocProvider<EmergencyBloc>.value(
          value: mockEmergencyBloc,
          child: const EmergencySosButton(
            tripId: TripId('trip-1'),
            routeId: RouteId('route-1'),
          ),
        ),
      ),
    );
  }

  group('EmergencySosButton Widget Tests', () {
    testWidgets('renders SOS FAB in idle state', (WidgetTester tester) async {
      when(() => mockEmergencyBloc.state).thenReturn(const EmergencyIdle());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('طوارئ'), findsOneWidget);
      expect(find.byIcon(Icons.sos), findsOneWidget);
    });

    testWidgets(
        'opens confirmation dialog on tap and triggers emergency on swipe',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockEmergencyBloc.state).thenReturn(const EmergencyIdle());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the SOS button
      await tester.tap(find.text('طوارئ'));
      await tester.pumpAndSettle();

      // Expect confirmation dialog
      expect(find.byType(SayrDialog), findsOneWidget);
      expect(
        find.text(
          'هل تريد فعلاً إرسال تنبيه طوارئ؟ سيتم إخطار المسؤولين بموقعك الحالي.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SwipeButton), findsOneWidget);

      // Swipe to confirm
      final thumb = find.byIcon(Icons.double_arrow_rounded);
      expect(thumb, findsOneWidget);
      // Programmatically trigger swipe action
      final swipeButton = tester.widget<SwipeButton>(find.byType(SwipeButton));
      swipeButton.onSwipe?.call();
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(SayrDialog), findsNothing);

      // Verify that trigger event is dispatched
      verify(() => mockEmergencyBloc.add(any(that: isA<EmergencyTriggered>())))
          .called(1);
    });

    testWidgets('renders loading state when emergency is sending',
        (WidgetTester tester) async {
      when(() => mockEmergencyBloc.state).thenReturn(const EmergencySending());

      await tester.pumpWidget(buildTestWidget());
      await tester
          .pump(); // Use pump instead of pumpAndSettle due to active animation

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('جاري الإرسال...'), findsOneWidget);
    });

    testWidgets(
        'renders checkmark and sent status in active state, and cancels on tap',
        (WidgetTester tester) async {
      final report = EmergencyReport(
        id: const EmergencyReportId('report-1'),
        userId: const UserId('user-1'),
        tripId: const TripId('trip-1'),
        location: const Coordinates(latitude: 33.3, longitude: 44.3),
        createdAt: DateTime.now(),
      );
      when(() => mockEmergencyBloc.state)
          .thenReturn(EmergencyActive(report: report));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('تم الإرسال'), findsOneWidget);

      // Tap on the button to cancel emergency
      await tester.tap(find.text('تم الإرسال'));
      await tester.pumpAndSettle();

      verify(() => mockEmergencyBloc.add(const EmergencyCancelled())).called(1);
    });
  });
}
