import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/ble_otp_cubit.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockBleBeaconService extends Mock implements BleBeaconService {}

class MockTripRepository extends Mock implements TripRepository {}

class MockTalker extends Mock implements Talker {}

void main() {
  setUpAll(() {
    registerFallbackValue(const TripId('fallback'));
    registerFallbackValue(DateTime.now());
  });

  late MockBleBeaconService mockBleBeaconService;
  late MockTripRepository mockTripRepo;
  late MockTalker mockTalker;
  late BleOtpCubit cubit;

  setUp(() {
    mockBleBeaconService = MockBleBeaconService();
    mockTripRepo = MockTripRepository();
    mockTalker = MockTalker();

    when(() => mockTalker.debug(any<dynamic>())).thenAnswer((_) {});
    when(() => mockTalker.warning(any<dynamic>())).thenAnswer((_) {});
    when(
      () => mockTalker.error(
        any<dynamic>(),
        any<Object?>(),
        any<StackTrace?>(),
      ),
    ).thenAnswer((_) {});

    cubit = BleOtpCubit(
      bleBeaconService: mockBleBeaconService,
      tripRepository: mockTripRepo,
      talker: mockTalker,
    );
  });

  tearDown(() => cubit.close());

  test('initial state is BleOtpInitial', () {
    expect(cubit.state, isA<BleOtpInitial>());
  });

  blocTest<BleOtpCubit, BleOtpState>(
    'startRotatingOtp calls repository and starts advertising BLE',
    build: () {
      when(
        () => mockTripRepo.updateBleOtp(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      when(
        () => mockBleBeaconService.startAdvertising(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async {});

      return cubit;
    },
    act: (cubit) => cubit.startRotatingOtp(const TripId('trip-123')),
    expect: () => [
      isA<BleOtpRotating>(),
    ],
    verify: (_) {
      verify(
        () => mockTripRepo.updateBleOtp(
          tripId: const TripId('trip-123'),
          otp: any(named: 'otp'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).called(1);

      verify(
        () => mockBleBeaconService.startAdvertising(
          tripId: const TripId('trip-123'),
          otp: any(named: 'otp'),
        ),
      ).called(1);
    },
  );

  blocTest<BleOtpCubit, BleOtpState>(
    'startRotatingOtp still advertises when updateBleOtp fails (Offline resilience)',
    build: () {
      when(
        () => mockTripRepo.updateBleOtp(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'Offline')));

      when(
        () => mockBleBeaconService.startAdvertising(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
        ),
      ).thenAnswer((_) async {});

      return cubit;
    },
    act: (cubit) => cubit.startRotatingOtp(const TripId('trip-123')),
    expect: () => [
      isA<BleOtpRotating>(),
    ],
    verify: (_) {
      verify(
        () => mockBleBeaconService.startAdvertising(
          tripId: const TripId('trip-123'),
          otp: any(named: 'otp'),
        ),
      ).called(1);
    },
  );

  blocTest<BleOtpCubit, BleOtpState>(
    'stopRotatingOtp stops advertising and cancels timer',
    build: () {
      when(() => mockBleBeaconService.stopAdvertising())
          .thenAnswer((_) async {});
      return cubit;
    },
    act: (cubit) => cubit.stopRotatingOtp(),
    expect: () => [
      isA<BleOtpStopped>(),
    ],
    verify: (_) {
      verify(() => mockBleBeaconService.stopAdvertising()).called(1);
    },
  );
}
