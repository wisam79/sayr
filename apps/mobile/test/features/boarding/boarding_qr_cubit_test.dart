import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/features/boarding/presentation/bloc/boarding_qr_cubit.dart';

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

  tearDown(() {
    bleController.close();
  });

  group('BoardingQrCubit', () {
    test('initial state is BoardingQrInitial', () {
      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );
      addTearDown(cubit.close);
      expect(cubit.state, isA<BoardingQrInitial>());
    });

    test('start() reaches Ready state with correct token details', () async {
      const tripId = TripId('trip-1');
      final expiresAt = DateTime.now().add(const Duration(seconds: 60));
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Right<Failure, TripId?>(tripId),
      );
      when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
        (_) async => Right<Failure, BoardingTokenResult>(
          BoardingTokenResult(token: 'token-abc', expiresAt: expiresAt),
        ),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BoardingQrReady>());
      final ready = cubit.state as BoardingQrReady;
      expect(ready.tripId, tripId);
      expect(ready.token, equals('token-abc'));
      expect(ready.expiresAt, equals(expiresAt));
      expect(ready.secondsUntilRefresh, inInclusiveRange(55, 60));

      verify(() => mockRepo.getActiveTripForSubscription()).called(1);
      verify(() => mockRepo.generateBoardingToken(tripId)).called(1);
      verify(() => mockBle.startScanning()).called(1);

      await cubit.close();
    });

    test('start() emits Loading then Ready on success', () async {
      const tripId = TripId('trip-1');
      final expiresAt = DateTime.now().add(const Duration(seconds: 60));
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Right<Failure, TripId?>(tripId),
      );
      when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
        (_) async => Right<Failure, BoardingTokenResult>(
          BoardingTokenResult(token: 'token-abc', expiresAt: expiresAt),
        ),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );
      final emitted = <BoardingQrState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(2));
      expect(emitted[0], isA<BoardingQrLoading>());
      expect(emitted[1], isA<BoardingQrReady>());

      await sub.cancel();
      await cubit.close();
    });

    test('start() emits BoardingQrNoActiveTrip when no active trip exists',
        () async {
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Right<Failure, TripId?>(null),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );
      final emitted = <BoardingQrState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BoardingQrNoActiveTrip>());
      expect(emitted, hasLength(2));
      expect(emitted[0], isA<BoardingQrLoading>());
      expect(emitted[1], isA<BoardingQrNoActiveTrip>());

      verifyNever(() => mockRepo.generateBoardingToken(any()));
      verifyNever(() => mockBle.startScanning());

      await sub.cancel();
      await cubit.close();
    });

    test('start() emits BoardingQrError on repository failure', () async {
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Left<Failure, TripId?>(
          ServerFailure(message: 'no internet'),
        ),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BoardingQrError>());
      final error = cubit.state as BoardingQrError;
      expect(error.message, equals('no internet'));

      await cubit.close();
    });

    test('start() falls back to unknown_error when failure.message is null',
        () async {
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Left<Failure, TripId?>(ServerFailure(message: null)),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      final error = cubit.state as BoardingQrError;
      expect(error.message, equals('unknown_error'));

      await cubit.close();
    });

    test('token generation failure emits BoardingQrError', () async {
      const tripId = TripId('trip-1');
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Right<Failure, TripId?>(tripId),
      );
      when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
        (_) async => const Left<Failure, BoardingTokenResult>(
          ServerFailure(message: 'rate limit'),
        ),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BoardingQrError>());
      final error = cubit.state as BoardingQrError;
      expect(error.message, equals('rate limit'));

      verify(() => mockRepo.generateBoardingToken(tripId)).called(1);

      await cubit.close();
    });

    test('BoardingQrReady.copyWith updates only specified fields', () {
      final original = BoardingQrReady(
        tripId: const TripId('trip-1'),
        token: 'old-token',
        expiresAt: DateTime(2026, 6, 7, 9),
        secondsUntilRefresh: 30,
      );
      final updated = original.copyWith(token: 'new-token');

      expect(updated.tripId, original.tripId);
      expect(updated.token, equals('new-token'));
      expect(updated.secondsUntilRefresh, equals(30));
    });

    test('BLE discovery of matching trip updates proximityOtp', () async {
      const tripId = TripId('trip-1');
      final expiresAt = DateTime.now().add(const Duration(seconds: 60));
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Right<Failure, TripId?>(tripId),
      );
      when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
        (_) async => Right<Failure, BoardingTokenResult>(
          BoardingTokenResult(token: 'token-abc', expiresAt: expiresAt),
        ),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<BoardingQrReady>());
      var ready = cubit.state as BoardingQrReady;
      expect(ready.proximityOtp, isNull);

      // Emit matching trip
      bleController.add((tripId: tripId, otp: 'ABC123'));
      await Future<void>.delayed(Duration.zero);

      ready = cubit.state as BoardingQrReady;
      expect(ready.proximityOtp, equals('ABC123'));

      await cubit.close();
    });

    test(
        'submitProximityCheckIn success emits loading state then success record',
        () async {
      const tripId = TripId('trip-1');
      final expiresAt = DateTime.now().add(const Duration(seconds: 60));
      when(() => mockRepo.getActiveTripForSubscription()).thenAnswer(
        (_) async => const Right<Failure, TripId?>(tripId),
      );
      when(() => mockRepo.generateBoardingToken(any())).thenAnswer(
        (_) async => Right<Failure, BoardingTokenResult>(
          BoardingTokenResult(token: 'token-abc', expiresAt: expiresAt),
        ),
      );

      final cubit = BoardingQrCubit(
        boardingRepository: mockRepo,
        bleBeaconService: mockBle,
      );

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      // Put cubit in ready state with proximity OTP
      bleController.add((tripId: tripId, otp: 'ABC123'));
      await Future<void>.delayed(Duration.zero);

      final record = BoardingRecord(
        id: const BoardingId('rec-1'),
        tripId: tripId,
        subscriptionId: const SubscriptionId('sub-1'),
        studentId: const UserId('student-1'),
        studentName: 'Ahmed Ali',
        boardedAt: DateTime.now(),
        boardingMethod: 'self_check_in',
      );

      when(
        () => mockRepo.validateBoardingViaProximity(
          tripId: tripId,
          otp: 'ABC123',
        ),
      ).thenAnswer((_) async => Right<Failure, BoardingRecord>(record));

      final emitted = <BoardingQrState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.submitProximityCheckIn(null);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first, isA<BoardingQrReady>());
      expect((emitted.first as BoardingQrReady).isSubmittingProximity, isTrue);

      expect(emitted[1], isA<BoardingQrReady>());
      final finalState = emitted[1] as BoardingQrReady;
      expect(finalState.isSubmittingProximity, isFalse);
      expect(finalState.proximityRecord, equals(record));

      await sub.cancel();
      await cubit.close();
    });
  });
}
