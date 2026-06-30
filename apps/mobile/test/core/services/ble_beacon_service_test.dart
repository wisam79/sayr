import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTalker extends Mock implements Talker {}

void main() {
  late BleBeaconService service;
  late MockTalker mockTalker;

  setUp(() {
    mockTalker = MockTalker();
    service = BleBeaconService(mockTalker);

    registerFallbackValue(const TripId('trip-123'));
    registerFallbackValue(DateTime.now());

    when(() => mockTalker.debug(any<dynamic>())).thenAnswer((_) {});
    when(() => mockTalker.warning(any<dynamic>())).thenAnswer((_) {});
    when(
      () => mockTalker.error(
        any<dynamic>(),
        any<Object?>(),
        any<StackTrace?>(),
      ),
    ).thenAnswer((_) {});
  });

  tearDown(() {
    service.stopScanning();
  });

  group('BleBeaconService', () {
    test('startAdvertising and stopAdvertising fall back to mock mode',
        () async {
      // In tests, flutter_ble_peripheral will either throw or report isSupported = false,
      // which will trigger the mock advertising mode.
      await service.startAdvertising(
        tripId: const TripId('trip-abc'),
        otp: 'ABC123',
      );

      // Verify that calling stopAdvertising runs without errors
      await service.stopAdvertising();
    });

    test(
        'startScanning and stopScanning fall back to mock mode and emit scan result',
        () async {
      // Since it runs in a test environment, Bluetooth won't be supported or enabled,
      // causing it to fall back to mock scanning.
      final isRealScanStarted = await service.startScanning();
      expect(isRealScanStarted, isFalse);

      // Wait 3.5 seconds for the mock scanning to emit the fake result.
      // We can use a Stream expectation to verify it emits.
      final emission = await service.discoveredTrips.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Mock scan result not emitted'),
      );

      expect(emission.tripId, const TripId('mock-trip-id-12345'));
      expect(emission.otp, 'MOCK12');

      await service.stopScanning();
    });
  });
}
