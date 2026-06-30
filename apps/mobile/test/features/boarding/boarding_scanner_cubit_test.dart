import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/boarding/presentation/bloc/boarding_scanner_cubit.dart';

class MockBoardingRepository extends Mock implements BoardingRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const TripId('fallback'));
    registerFallbackValue(Coordinates(latitude: 0, longitude: 0));
  });

  late MockBoardingRepository mockRepo;
  late StreamController<List<BoardingRecord>> passengerController;
  const testTripId = TripId('trip-1');

  BoardingRecord makeRecord({
    String? id = 'rec-1',
    String? studentId = 'user-1',
    String? studentName = 'Ahmed',
    BoardingMethod method = BoardingMethod.qrScan,
    DateTime? boardedAt,
  }) {
    return BoardingRecord(
      id: BoardingId(id!),
      tripId: testTripId,
      subscriptionId: const SubscriptionId('sub-1'),
      studentId: UserId(studentId!),
      studentName: studentName,
      boardedAt: boardedAt ?? DateTime(2026, 6, 7, 8),
      boardingMethod: method,
    );
  }

  setUp(() {
    mockRepo = MockBoardingRepository();
    passengerController = StreamController<List<BoardingRecord>>.broadcast();
    when(() => mockRepo.watchTripPassengers(any()))
        .thenAnswer((_) => passengerController.stream);
  });

  tearDown(() async {
    await passengerController.close();
  });

  BoardingScannerCubit buildCubit() {
    return BoardingScannerCubit(
      boardingRepository: mockRepo,
      tripId: testTripId,
    );
  }

  group('BoardingScannerCubit', () {
    test('initial state is BoardingScannerInitial', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      expect(cubit.state, isA<BoardingScannerInitial>());
    });

    blocTest<BoardingScannerCubit, BoardingScannerState>(
      'start() emits Ready with passengers when stream produces data',
      build: buildCubit,
      act: (cubit) async {
        cubit.start();
        await Future<void>.delayed(Duration.zero);
        passengerController.add([makeRecord()]);
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<BoardingScannerReady>());
        final ready = state as BoardingScannerReady;
        expect(ready.tripId, testTripId);
        expect(ready.passengers, hasLength(1));
        expect(ready.passengers.first.studentId, const UserId('user-1'));
        expect(ready.lastScan, isNull);
      },
    );

    blocTest<BoardingScannerCubit, BoardingScannerState>(
      'start() emits Ready with empty list when stream emits []',
      build: buildCubit,
      act: (cubit) async {
        cubit.start();
        await Future<void>.delayed(Duration.zero);
        passengerController.add(<BoardingRecord>[]);
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<BoardingScannerReady>());
        expect((state as BoardingScannerReady).passengers, isEmpty);
      },
    );

    blocTest<BoardingScannerCubit, BoardingScannerState>(
      'stream error emits BoardingScannerError',
      build: buildCubit,
      act: (cubit) async {
        cubit.start();
        await Future<void>.delayed(Duration.zero);
        passengerController.addError(Exception('realtime disconnected'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<BoardingScannerError>());
        expect(
          (state as BoardingScannerError).failure.message,
          contains('realtime disconnected'),
        );
      },
    );

    blocTest<BoardingScannerCubit, BoardingScannerState>(
      'processToken on success emits Ready with lastScan = BoardingScanSuccess',
      build: () {
        when(
          () => mockRepo.validateBoarding(
            token: any(named: 'token'),
            tripId: any(named: 'tripId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, BoardingRecord>(
            makeRecord(
              id: 'rec-99',
              studentName: 'New Student',
            ),
          ),
        );
        return buildCubit();
      },
      act: (cubit) async {
        cubit.start();
        passengerController.add([]);
        await Future<void>.delayed(Duration.zero);
        await cubit.processToken('raw-token-xyz');
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<BoardingScannerReady>());
        final ready = state as BoardingScannerReady;
        expect(ready.lastScan, isA<BoardingScanSuccess>());
        final success = ready.lastScan! as BoardingScanSuccess;
        expect(success.record.id, const BoardingId('rec-99'));
        expect(success.record.studentName, equals('New Student'));
      },
    );

    blocTest<BoardingScannerCubit, BoardingScannerState>(
      'processToken on failure emits Ready with lastScan = BoardingScanFailure',
      build: () {
        when(
          () => mockRepo.validateBoarding(
            token: any(named: 'token'),
            tripId: any(named: 'tripId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, BoardingRecord>(
            ServerFailure(message: 'expired token'),
          ),
        );
        return buildCubit();
      },
      act: (cubit) async {
        cubit.start();
        passengerController.add([]);
        await Future<void>.delayed(Duration.zero);
        await cubit.processToken('stale-token');
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<BoardingScannerReady>());
        final ready = state as BoardingScannerReady;
        expect(ready.lastScan, isA<BoardingScanFailure>());
        final failure = ready.lastScan! as BoardingScanFailure;
        expect(failure.failure.message, equals('expired token'));
      },
    );

    blocTest<BoardingScannerCubit, BoardingScannerState>(
      'processToken with unknown error uses unknown_error fallback',
      build: () {
        when(
          () => mockRepo.validateBoarding(
            token: any(named: 'token'),
            tripId: any(named: 'tripId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, BoardingRecord>(ServerFailure()),
        );
        return buildCubit();
      },
      act: (cubit) async {
        cubit.start();
        passengerController.add([]);
        await Future<void>.delayed(Duration.zero);
        await cubit.processToken('bad-token');
      },
      verify: (cubit) {
        final ready = cubit.state as BoardingScannerReady;
        final failure = ready.lastScan! as BoardingScanFailure;
        expect(failure.failure, const ServerFailure());
      },
    );

    blocTest<BoardingScannerCubit, BoardingScannerState>(
      'processToken forwards driverLocation coordinates to repository',
      build: () {
        when(
          () => mockRepo.validateBoarding(
            token: any(named: 'token'),
            tripId: any(named: 'tripId'),
            driverLocation: any(named: 'driverLocation'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, BoardingRecord>(makeRecord()),
        );
        return buildCubit();
      },
      act: (cubit) async {
        cubit.start();
        passengerController.add([]);
        await Future<void>.delayed(Duration.zero);
        await cubit.processToken(
          'token-abc',
          driverLocation:
              Coordinates(latitude: 33.315, longitude: 44.366),
        );
      },
      verify: (_) {
        verify(
          () => mockRepo.validateBoarding(
            token: 'token-abc',
            tripId: testTripId,
            driverLocation:
                Coordinates(latitude: 33.315, longitude: 44.366),
          ),
        ).called(1);
      },
    );

    test('start() called twice replaces the previous subscription', () async {
      final cubit = buildCubit()
        ..start()
        ..start();
      verify(() => mockRepo.watchTripPassengers(testTripId)).called(2);
      await cubit.close();
    });
  });
}
