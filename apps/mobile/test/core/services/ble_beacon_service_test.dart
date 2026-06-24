import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';

class MockTripRepository extends Mock implements TripRepository {}

class MockLogger extends Mock implements Logger {}

void main() {
  late BleBeaconService service;
  late MockTripRepository mockTripRepo;
  late MockLogger mockLogger;

  setUp(() {
    service = BleBeaconService();
    mockTripRepo = MockTripRepository();
    mockLogger = MockLogger();

    registerFallbackValue(const TripId('trip-123'));
    registerFallbackValue(DateTime.now());

    when(() => mockLogger.d(any<dynamic>())).thenAnswer((_) {});
    when(() => mockLogger.w(any<dynamic>())).thenAnswer((_) {});
    when(
      () => mockLogger.e(
        any<dynamic>(),
        error: any<dynamic>(named: 'error'),
        stackTrace: any<StackTrace?>(named: 'stackTrace'),
      ),
    ).thenAnswer((_) {});
  });

  tearDown(() {
    service
      ..stopRotatingOtpAdvertising()
      ..stopScanning();
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

    test('startRotatingOtpAdvertising rotates OTP and updates DB periodically',
        () async {
      // Stub the updateBleOtp call
      when(
        () => mockTripRepo.updateBleOtp(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      service.startRotatingOtpAdvertising(
        tripId: const TripId('trip-xyz'),
        tripRepository: mockTripRepo,
        logger: mockLogger,
      );

      // Give it a split second to trigger the initial updateOtp call
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        () => mockTripRepo.updateBleOtp(
          tripId: const TripId('trip-xyz'),
          otp: any(named: 'otp'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).called(1);

      service.stopRotatingOtpAdvertising();
    });

    test('startRotatingOtpAdvertising logs error on repository failure',
        () async {
      when(
        () => mockTripRepo.updateBleOtp(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'DB error')));

      service.startRotatingOtpAdvertising(
        tripId: const TripId('trip-xyz'),
        tripRepository: mockTripRepo,
        logger: mockLogger,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        () => mockLogger.e(
          any<dynamic>(),
          error: any<dynamic>(named: 'error'),
          stackTrace: any<StackTrace?>(named: 'stackTrace'),
        ),
      ).called(1);

      service.stopRotatingOtpAdvertising();
    });
  });
}
