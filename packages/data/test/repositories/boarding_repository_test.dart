import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'package:talker_flutter/talker_flutter.dart';

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

void main() {
  late BoardingRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    repository = BoardingRepositoryImpl(
      remoteDatasource: mockRemote,
      talker: Talker(),
    );
  });

  const testTripId = TripId('trip-1');
  final testExpiresAt = DateTime(2026, 6, 7, 8, 1);

  group('getActiveTripForSubscription', () {
    test('returns Right<Failure, TripId?> with TripId on success', () async {
      when(() => mockRemote.getActiveTripForSubscription())
          .thenAnswer((_) async => 'trip-1');

      final result = await repository.getActiveTripForSubscription();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('expected success, got $failure'),
        (tripId) => expect(tripId, equals(testTripId)),
      );
      verify(() => mockRemote.getActiveTripForSubscription()).called(1);
    });

    test('returns Right<Failure, TripId?> with null when no active trip',
        () async {
      when(() => mockRemote.getActiveTripForSubscription())
          .thenAnswer((_) async => null);

      final result = await repository.getActiveTripForSubscription();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('expected success, got $failure'),
        (tripId) => expect(tripId, isNull),
      );
    });

    test('returns Left<ServerFailure> on exception', () async {
      when(() => mockRemote.getActiveTripForSubscription())
          .thenThrow(Exception('boom'));

      final result = await repository.getActiveTripForSubscription();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('boom'));
        },
        (_) => fail('expected failure'),
      );
    });
  });

  group('generateBoardingToken', () {
    test('returns Right<Failure, BoardingTokenResult> on success', () async {
      when(() => mockRemote.generateBoardingToken('trip-1')).thenAnswer(
        (_) async => (token: 'raw-token-xyz', expiresAt: testExpiresAt),
      );

      final result = await repository.generateBoardingToken(testTripId);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('expected success, got $failure'),
        (tokenResult) {
          expect(tokenResult.token, equals('raw-token-xyz'));
          expect(tokenResult.expiresAt, equals(testExpiresAt));
        },
      );
      verify(() => mockRemote.generateBoardingToken('trip-1')).called(1);
    });

    test('returns Left<ServerFailure> on exception', () async {
      when(() => mockRemote.generateBoardingToken('trip-1'))
          .thenThrow(Exception('rate limit'));

      final result = await repository.generateBoardingToken(testTripId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('rate limit'));
        },
        (_) => fail('expected failure'),
      );
    });
  });

  group('validateBoarding', () {
    test('returns Right<Failure, BoardingRecord> on success', () async {
      when(
        () => mockRemote.validateBoarding(
          token: 'raw-token-xyz',
          tripId: 'trip-1',
        ),
      ).thenAnswer(
        (_) async => {
          'boarding_id': 'rec-1',
          'subscription_id': 'sub-1',
          'student_id': 'user-1',
          'student_name': 'Ahmed Ali',
          'boarded_at': '2026-06-07T08:00:30Z',
        },
      );

      final result = await repository.validateBoarding(
        token: 'raw-token-xyz',
        tripId: testTripId,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('expected success, got $failure'),
        (record) {
          expect(record.id, const BoardingId('rec-1'));
          expect(record.tripId, testTripId);
          expect(record.subscriptionId, const SubscriptionId('sub-1'));
          expect(record.studentId, const UserId('user-1'));
          expect(record.studentName, equals('Ahmed Ali'));
          expect(record.boardingMethod, BoardingMethod.qrScan);
        },
      );
    });

    test('forwards driverLocation latitude/longitude to the remote call',
        () async {
      final driverLocation = Coordinates(latitude: 33.315, longitude: 44.366);
      when(
        () => mockRemote.validateBoarding(
          token: 'raw-token-xyz',
          tripId: 'trip-1',
          lat: 33.315,
          lng: 44.366,
        ),
      ).thenAnswer(
        (_) async => {
          'boarding_id': 'rec-1',
          'subscription_id': 'sub-1',
          'student_id': 'user-1',
          'student_name': null,
          'boarded_at': '2026-06-07T08:00:30Z',
        },
      );

      final result = await repository.validateBoarding(
        token: 'raw-token-xyz',
        tripId: testTripId,
        driverLocation: driverLocation,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRemote.validateBoarding(
          token: 'raw-token-xyz',
          tripId: 'trip-1',
          lat: 33.315,
          lng: 44.366,
        ),
      ).called(1);
    });

    test('returns Left<ServerFailure> on exception', () async {
      when(
        () => mockRemote.validateBoarding(
          token: any(named: 'token'),
          tripId: any(named: 'tripId'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenThrow(Exception('invalid token'));

      final result = await repository.validateBoarding(
        token: 'bad-token',
        tripId: testTripId,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('invalid token'));
        },
        (_) => fail('expected failure'),
      );
    });
  });

  group('getTripPassengers', () {
    test('maps row map list to BoardingRecord entities', () async {
      when(() => mockRemote.getTripPassengers('trip-1')).thenAnswer(
        (_) async => [
          {
            'boarding_id': 'rec-1',
            'student_id': 'user-1',
            'student_name': 'Ahmed Ali',
            'boarded_at': '2026-06-07T08:00:30Z',
            'boarding_method': 'qr_scan',
          },
          {
            'boarding_id': 'rec-2',
            'student_id': 'user-2',
            'student_name': 'Sara Hassan',
            'boarded_at': '2026-06-07T08:00:45Z',
            'boarding_method': 'manual',
          },
        ],
      );

      final result = await repository.getTripPassengers(testTripId);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('expected success, got $failure'),
        (records) {
          expect(records, hasLength(2));
          expect(records[0].id, const BoardingId('rec-1'));
          expect(records[0].studentName, equals('Ahmed Ali'));
          expect(records[0].boardingMethod, BoardingMethod.qrScan);
          expect(records[1].id, const BoardingId('rec-2'));
          expect(records[1].boardingMethod, BoardingMethod.manual);
        },
      );
    });

    test('defaults boardingMethod to qr_scan when null in row', () async {
      when(() => mockRemote.getTripPassengers('trip-1')).thenAnswer(
        (_) async => [
          {
            'boarding_id': 'rec-1',
            'student_id': 'user-1',
            'student_name': 'Ahmed',
            'boarded_at': '2026-06-07T08:00:30Z',
            'boarding_method': null,
          },
        ],
      );

      final result = await repository.getTripPassengers(testTripId);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected success'),
        (records) {
          expect(records.first.boardingMethod, BoardingMethod.qrScan);
        },
      );
    });

    test('returns empty list when no passengers boarded', () async {
      when(() => mockRemote.getTripPassengers('trip-1'))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      final result = await repository.getTripPassengers(testTripId);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected success'),
        (records) => expect(records, isEmpty),
      );
    });

    test('returns Left<ServerFailure> on exception', () async {
      when(() => mockRemote.getTripPassengers('trip-1'))
          .thenThrow(Exception('db down'));

      final result = await repository.getTripPassengers(testTripId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('expected failure'),
      );
    });
  });

  group('watchTripPassengers', () {
    test('emits mapped entities when the stream produces data', () async {
      final controller = StreamController<List<Map<String, dynamic>>>();
      when(() => mockRemote.watchTripPassengers('trip-1'))
          .thenAnswer((_) => controller.stream);

      final stream = repository.watchTripPassengers(testTripId);

      expect(
        stream,
        emitsInOrder([
          [
            isA<BoardingRecord>()
                .having((r) => r.id, 'id', const BoardingId('rec-1'))
                .having(
                  (r) => r.studentId,
                  'studentId',
                  const UserId('user-1'),
                )
                .having((r) => r.boardingMethod, 'boardingMethod',
                    BoardingMethod.qrScan),
          ],
        ]),
      );

      controller.add([
        {
          'id': 'rec-1',
          'subscription_id': 'sub-1',
          'student_id': 'user-1',
          'boarded_at': '2026-06-07T08:00:30Z',
          'boarding_method': 'qr_scan',
        },
      ]);

      await controller.close();
    });

    test('propagates multiple emissions in order', () async {
      final controller = StreamController<List<Map<String, dynamic>>>();
      when(() => mockRemote.watchTripPassengers('trip-1'))
          .thenAnswer((_) => controller.stream);

      final stream = repository.watchTripPassengers(testTripId);

      expect(
        stream,
        emitsInOrder([
          hasLength(0),
          hasLength(1),
        ]),
      );

      controller
        ..add(<Map<String, dynamic>>[])
        ..add([
          {
            'id': 'rec-1',
            'subscription_id': 'sub-1',
            'student_id': 'user-1',
            'boarded_at': '2026-06-07T08:00:30Z',
            'boarding_method': 'qr_scan',
          },
        ]);

      await controller.close();
    });

    test('defaults boardingMethod to qr_scan when null in stream row',
        () async {
      final controller = StreamController<List<Map<String, dynamic>>>();
      when(() => mockRemote.watchTripPassengers('trip-1'))
          .thenAnswer((_) => controller.stream);

      final stream = repository.watchTripPassengers(testTripId);

      expect(
        stream,
        emitsInOrder([
          [
            isA<BoardingRecord>().having(
              (r) => r.boardingMethod,
              'boardingMethod',
              BoardingMethod.qrScan,
            ),
          ],
        ]),
      );

      controller.add([
        {
          'id': 'rec-1',
          'subscription_id': 'sub-1',
          'student_id': 'user-1',
          'boarded_at': '2026-06-07T08:00:30Z',
          'boarding_method': null,
        },
      ]);

      await controller.close();
    });
  });

  group('validateBoardingViaProximity', () {
    test('returns Right<Failure, BoardingRecord> on success', () async {
      when(
        () => mockRemote.validateBoardingViaProximity(
          tripId: 'trip-1',
          otp: '123456',
        ),
      ).thenAnswer(
        (_) async => {
          'boarding_id': 'rec-1',
          'subscription_id': 'sub-1',
          'student_id': 'user-1',
          'student_name': 'Ahmed Ali',
          'boarded_at': '2026-06-07T08:00:30Z',
        },
      );

      final result = await repository.validateBoardingViaProximity(
        tripId: testTripId,
        otp: '123456',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('expected success, got $failure'),
        (record) {
          expect(record.id, const BoardingId('rec-1'));
          expect(record.tripId, testTripId);
          expect(record.subscriptionId, const SubscriptionId('sub-1'));
          expect(record.studentId, const UserId('user-1'));
          expect(record.studentName, equals('Ahmed Ali'));
          expect(record.boardingMethod, BoardingMethod.selfCheckIn);
        },
      );
    });

    test('forwards studentLocation latitude/longitude to the remote call',
        () async {
      final studentLocation = Coordinates(latitude: 33.315, longitude: 44.366);
      when(
        () => mockRemote.validateBoardingViaProximity(
          tripId: 'trip-1',
          otp: '123456',
          lat: 33.315,
          lng: 44.366,
        ),
      ).thenAnswer(
        (_) async => {
          'boarding_id': 'rec-1',
          'subscription_id': 'sub-1',
          'student_id': 'user-1',
          'student_name': null,
          'boarded_at': '2026-06-07T08:00:30Z',
        },
      );

      final result = await repository.validateBoardingViaProximity(
        tripId: testTripId,
        otp: '123456',
        studentLocation: studentLocation,
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRemote.validateBoardingViaProximity(
          tripId: 'trip-1',
          otp: '123456',
          lat: 33.315,
          lng: 44.366,
        ),
      ).called(1);
    });

    test('returns Left<ServerFailure> on exception', () async {
      when(
        () => mockRemote.validateBoardingViaProximity(
          tripId: any(named: 'tripId'),
          otp: any(named: 'otp'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenThrow(Exception('invalid otp'));

      final result = await repository.validateBoardingViaProximity(
        tripId: testTripId,
        otp: 'wrong-otp',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('invalid otp'));
        },
        (_) => fail('expected failure'),
      );
    });
  });
}
