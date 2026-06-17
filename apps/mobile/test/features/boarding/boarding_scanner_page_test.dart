import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/boarding/presentation/pages/boarding_scanner_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockBoardingRepository extends Mock implements BoardingRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const TripId('fallback'));
  });

  late MockBoardingRepository mockRepo;
  late StreamController<List<BoardingRecord>> passengerController;
  const testTripId = TripId('trip-1');

  setUp(() {
    mockRepo = MockBoardingRepository();
    passengerController = StreamController<List<BoardingRecord>>.broadcast();

    when(() => mockRepo.watchTripPassengers(any()))
        .thenAnswer((_) => passengerController.stream);
  });

  tearDown(() async {
    await passengerController.close();
    await GetIt.I.reset();
  });

  Widget wrap() {
    GetIt.I.registerFactory<BoardingRepository>(() => mockRepo);
    return const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ar'),
      home: BoardingScannerPage(tripId: testTripId),
    );
  }

  BoardingRecord makeRecord({
    String id = 'rec-1',
    String studentName = 'محمد علي',
    DateTime? boardedAt,
  }) {
    return BoardingRecord(
      id: BoardingId(id),
      tripId: testTripId,
      subscriptionId: const SubscriptionId('sub-1'),
      studentId: const UserId('student-1'),
      studentName: studentName,
      boardedAt: boardedAt ?? DateTime(2026, 6, 9, 12),
      boardingMethod: 'qr_scan',
    );
  }

  testWidgets('renders scanner page title and empty state initially',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // Emits empty passengers list
    passengerController.add(<BoardingRecord>[]);
    await tester.pumpAndSettle();

    expect(find.text('مسح صعود الركاب'), findsOneWidget);
    expect(find.text('لم يصعد أحد بعد'), findsOneWidget);
  });

  testWidgets('renders list of passengers when they board', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // Emit some passengers
    final record1 = makeRecord(id: 'rec-1', studentName: 'محمد علي');
    final record2 = makeRecord(id: 'rec-2', studentName: 'أحمد سعيد');
    passengerController.add([record1, record2]);
    await tester.pumpAndSettle();

    expect(find.text('محمد علي'), findsOneWidget);
    expect(find.text('أحمد سعيد'), findsOneWidget);
    expect(
        find.text('الركاب (2)'), findsOneWidget); // l10n.boardingPassengers(2)
  });

  testWidgets('renders error message on stream error', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // Emit error
    passengerController.addError(Exception('فشل الاتصال الفوري'));
    await tester.pumpAndSettle();

    expect(find.textContaining('فشل الاتصال الفوري'), findsOneWidget);
  });
}
