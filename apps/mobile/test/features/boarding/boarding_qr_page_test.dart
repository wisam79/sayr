import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/features/boarding/presentation/pages/boarding_qr_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockBoardingRepository extends Mock implements BoardingRepository {}

class MockBleBeaconService extends Mock implements BleBeaconService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const TripId('fallback'));
  });

  late MockBoardingRepository mockRepo;
  late MockBleBeaconService mockBle;
  late StreamController<({TripId tripId, String otp})> bleController;

  setUp(() {
    mockRepo = MockBoardingRepository();
    mockBle = MockBleBeaconService();
    bleController = StreamController<({TripId tripId, String otp})>.broadcast();

    when(() => mockBle.startScanning()).thenAnswer((_) async {});
    when(() => mockBle.stopScanning()).thenAnswer((_) async {});
    when(() => mockBle.discoveredTrips).thenAnswer((_) => bleController.stream);
  });

  tearDown(() async {
    await bleController.close();
    await GetIt.I.reset();
  });

  Widget wrap() {
    GetIt.I.registerFactory<BoardingRepository>(() => mockRepo);
    GetIt.I.registerFactory<BleBeaconService>(() => mockBle);
    return const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ar'),
      home: BoardingQrPage(),
    );
  }

  Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('renders app bar with boarding title', (tester) async {
    when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
      (_) async => const Right<Failure, TripId?>(null),
    );

    await pumpAndSettle(tester);

    expect(find.text('الصعود إلى الحافلة'), findsOneWidget);
  });

  testWidgets('shows loading indicator while initial fetch is in-flight',
      (tester) async {
    final completer = Completer<Right<Failure, TripId?>>();
    when(() => mockRepo.getActiveTripForSubscription())
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const Right<Failure, TripId?>(null));
    await tester.pumpAndSettle();
  });

  testWidgets('shows "no active trip" message when subscription has no trip',
      (tester) async {
    when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
      (_) async => const Right<Failure, TripId?>(null),
    );

    await pumpAndSettle(tester);

    expect(find.text('لا توجد رحلة نشطة حالياً'), findsOneWidget);
    expect(
      find.textContaining('ستظهر رحلتك هنا'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.directions_bus_outlined), findsOneWidget);
    verifyNever(() => mockRepo.generateBoardingToken(any()));
  });

  testWidgets('shows error message with error icon on failure', (tester) async {
    when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
      (_) async => const Left<Failure, TripId?>(
        ServerFailure(message: 'فشل الاتصال'),
      ),
    );

    await pumpAndSettle(tester);

    expect(find.text('حدث خطأ'), findsOneWidget);
    expect(find.text('فشل الاتصال'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('shows "unknown error" text when failure message is null',
      (tester) async {
    when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
      (_) async => const Left<Failure, TripId?>(ServerFailure(message: null)),
    );

    await pumpAndSettle(tester);

    expect(find.text('حدث خطأ'), findsOneWidget);
    expect(find.text('unknown_error'), findsOneWidget);
  });

  testWidgets('shows QR code, countdown, and hint on Ready state',
      (tester) async {
    const tripId = TripId('trip-1');
    final expiresAt = DateTime.now().add(const Duration(seconds: 60));
    when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
      (_) async => const Right<Failure, TripId?>(tripId),
    );
    when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
      (_) async => Right<Failure, BoardingTokenResult>(
        BoardingTokenResult(
          token: 'qr-token-xyz',
          expiresAt: expiresAt,
        ),
      ),
    );

    await pumpAndSettle(tester);

    expect(find.text('اعرض هذا الرمز على السائق عند الصعود'), findsOneWidget);
    expect(
      find.text('الرمز يتجدد تلقائياً كل دقيقة'),
      findsOneWidget,
    );

    final countdownFinder = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.data != null &&
          w.data!.endsWith('s') &&
          w.data!.length <= 3,
    );
    expect(countdownFinder, findsOneWidget);
  });

  testWidgets('shows error from generateBoardingToken failure', (tester) async {
    const tripId = TripId('trip-1');
    when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
      (_) async => const Right<Failure, TripId?>(tripId),
    );
    when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
      (_) async => const Left<Failure, BoardingTokenResult>(
        ServerFailure(message: 'معدل الطلبات مرتفع'),
      ),
    );

    await pumpAndSettle(tester);

    expect(find.text('حدث خطأ'), findsOneWidget);
    expect(find.text('معدل الطلبات مرتفع'), findsOneWidget);
    verify(() => mockRepo.generateBoardingToken(tripId)).called(1);
  });

  testWidgets('renders proximity card and swipe button when near bus',
      (tester) async {
    const tripId = TripId('trip-1');
    final expiresAt = DateTime.now().add(const Duration(seconds: 60));
    when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
      (_) async => const Right<Failure, TripId?>(tripId),
    );
    when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
      (_) async => Right<Failure, BoardingTokenResult>(
        BoardingTokenResult(
          token: 'qr-token-xyz',
          expiresAt: expiresAt,
        ),
      ),
    );

    await pumpAndSettle(tester);

    // Verify it is in ready state and no proximity check-in widget is shown yet
    expect(find.text('أنت بالقرب من الحافلة'), findsNothing);

    // Emit the matching BLE beacon
    bleController.add((tripId: tripId, otp: 'ABC123'));
    await tester.pump(Duration.zero);
    await tester.pump();

    // Verify the proximity boarding card has appeared
    expect(find.text('أنت بالقرب من الحافلة'), findsOneWidget);
    expect(find.text('اسحب لتسجيل صعودك فوراً'), findsOneWidget);
    expect(find.text('اسحب لتأكيد الصعود'), findsOneWidget);
  });
}
