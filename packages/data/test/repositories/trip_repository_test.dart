import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

class MockLocalDatasource extends Mock implements LocalDatasource {}

class MockUser extends Mock implements supabase.User {}

void main() {
  late TripRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockLocalDatasource mockLocal;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockLocal = MockLocalDatasource();
    repository = TripRepositoryImpl(
      remoteDatasource: mockRemote,
      localDatasource: mockLocal,
    );
  });

  group('TripRepositoryImpl', () {
    final mockTripJson = {
      'id': 'trip-123',
      'route_id': 'route-456',
      'driver_id': 'driver-789',
      'status': 'scheduled',
      'scheduled_at': '2026-06-04T08:00:00Z',
    };

    group('getActiveTrips', () {
      test('returns List<Trip> on success', () async {
        when(() => mockRemote.getActiveTrips())
            .thenAnswer((_) async => [mockTripJson]);

        final result = await repository.getActiveTrips();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (trips) {
            expect(trips.length, 1);
            expect(trips.first.id, const TripId('trip-123'));
            expect(trips.first.status, TripStatus.scheduled);
          },
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getActiveTrips())
            .thenThrow(Exception('DB error'));

        final result = await repository.getActiveTrips();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('watchTrip', () {
      test('returns Stream of Trip', () async {
        final controller = StreamController<List<Map<String, dynamic>>>();
        when(() => mockRemote.watchTrip('trip-123'))
            .thenAnswer((_) => controller.stream);

        final stream = repository.watchTrip(const TripId('trip-123'));

        expect(
          stream,
          emitsInOrder([
            isA<Trip>()
                .having((t) => t.id, 'id', const TripId('trip-123'))
                .having((t) => t.status, 'status', TripStatus.scheduled),
          ]),
        );

        controller.add([mockTripJson]);

        await controller.close();
      });

      test('throws StateError when watch stream is empty', () async {
        final controller = StreamController<List<Map<String, dynamic>>>();
        when(() => mockRemote.watchTrip('trip-123'))
            .thenAnswer((_) => controller.stream);

        final stream = repository.watchTrip(const TripId('trip-123'));

        expect(stream, emitsError(isA<StateError>()));

        controller.add([]);

        await controller.close();
      });
    });

    group('createTrip', () {
      test('returns created Trip after RPC succeeds', () async {
        when(
          () => mockRemote.createTrip(
            routeId: 'route-456',
            scheduledAt: any(named: 'scheduledAt'),
          ),
        ).thenAnswer((_) async => 'trip-123');
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => mockTripJson);

        final result = await repository.createTrip(
          routeId: const RouteId('route-456'),
          scheduledAt: DateTime.parse('2026-06-04T08:00:00Z'),
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (trip) => expect(trip.id, const TripId('trip-123')),
        );
      });

      test('returns NotFoundFailure when created trip cannot be loaded',
          () async {
        when(
          () => mockRemote.createTrip(
            routeId: 'route-456',
            scheduledAt: any(named: 'scheduledAt'),
          ),
        ).thenAnswer((_) async => 'trip-123');
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => null);

        final result = await repository.createTrip(
          routeId: const RouteId('route-456'),
          scheduledAt: DateTime.parse('2026-06-04T08:00:00Z'),
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getById', () {
      test('returns Trip when found', () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => mockTripJson);

        final result = await repository.getById(const TripId('trip-123'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (trip) => expect(trip.id, const TripId('trip-123')),
        );
      });

      test('returns Left(NotFoundFailure) when not found', () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => null);

        final result = await repository.getById(const TripId('trip-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenThrow(Exception('Network issue'));

        final result = await repository.getById(const TripId('trip-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('updateStatus', () {
      test('successfully transitions state and updates status on remote',
          () async {
        // 1. Mock getById to return current trip in 'scheduled' state
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => mockTripJson);

        // 2. Mock updateTripStatus to transition from scheduled -> driver_waiting via startWaiting event
        final updatedTripJson = {
          ...mockTripJson,
          'status': 'driver_waiting',
        };

        when(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-123',
            newStatus: 'driver_waiting',
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => updatedTripJson);

        final result = await repository.updateStatus(
          tripId: const TripId('trip-123'),
          event: TripEvent.arrive,
          location: const Coordinates(latitude: 33.123, longitude: 44.456),
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (trip) => expect(trip.status, TripStatus.driverWaiting),
        );

        verify(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-123',
            newStatus: 'driver_waiting',
            lat: 33.123,
            lng: 44.456,
          ),
        ).called(1);
      });

      test('returns InvalidStateTransitionFailure on invalid transition',
          () async {
        // scheduled -> complete is invalid (can't go scheduled to completed directly)
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => mockTripJson);

        final result = await repository.updateStatus(
          tripId: const TripId('trip-123'),
          event: TripEvent.complete,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<InvalidStateTransitionFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns Left(Failure) when getById fails during updateStatus',
          () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenThrow(Exception('Fetch failed'));

        final result = await repository.updateStatus(
          tripId: const TripId('trip-123'),
          event: TripEvent.arrive,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when updateTripStatus throws exception',
          () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => mockTripJson);

        when(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-123',
            newStatus: 'driver_waiting',
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenThrow(Exception('Status update RPC failed'));

        final result = await repository.updateStatus(
          tripId: const TripId('trip-123'),
          event: TripEvent.arrive,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('updateLocation', () {
      test('calls updateTripLocation on remote datasource', () async {
        when(
          () => mockRemote.updateTripLocation(
            tripId: 'trip-123',
            lat: 33.123,
            lng: 44.456,
          ),
        ).thenAnswer((_) async {});

        final result = await repository.updateLocation(
          tripId: const TripId('trip-123'),
          lat: 33.123,
          lng: 44.456,
        );

        expect(result.isRight(), true);
        verify(
          () => mockRemote.updateTripLocation(
            tripId: 'trip-123',
            lat: 33.123,
            lng: 44.456,
          ),
        ).called(1);
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(
          () => mockRemote.updateTripLocation(
            tripId: 'trip-123',
            lat: 33.123,
            lng: 44.456,
          ),
        ).thenThrow(Exception('Update location failed'));

        final result = await repository.updateLocation(
          tripId: const TripId('trip-123'),
          lat: 33.123,
          lng: 44.456,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('bulkUpdateLocations', () {
      test('maps list and calls bulkUpdateTripLocations on remote datasource',
          () async {
        when(() => mockRemote.bulkUpdateTripLocations(any()))
            .thenAnswer((_) async {});

        final result = await repository.bulkUpdateLocations([
          (tripId: const TripId('trip-1'), lat: 33.0, lng: 44.0),
          (tripId: const TripId('trip-2'), lat: 33.1, lng: 44.1),
        ]);

        expect(result.isRight(), true);
        verify(
          () => mockRemote.bulkUpdateTripLocations([
            {'trip_id': 'trip-1', 'lat': 33.0, 'lng': 44.0},
            {'trip_id': 'trip-2', 'lat': 33.1, 'lng': 44.1},
          ]),
        ).called(1);
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.bulkUpdateTripLocations(any()))
            .thenThrow(Exception('Bulk insert failed'));

        final result = await repository.bulkUpdateLocations([
          (tripId: const TripId('trip-1'), lat: 33.0, lng: 44.0),
        ]);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('createPayment', () {
      test('returns PaymentInfo on success', () async {
        final mockPaymentJson = {
          'id': 'pay-123',
          'amount': 5000,
          'currency': 'IQD',
          'status': 'pending',
          'method': 'zain_cash',
          'payment_url': 'https://pay.zaincash.iq/transaction?id=123',
        };

        when(
          () => mockRemote.createPayment(
            routeId: 'route-1',
            amount: 5000,
            currency: 'IQD',
            method: 'zain_cash',
          ),
        ).thenAnswer((_) async => mockPaymentJson);

        final result = await repository.createPayment(
          routeId: const RouteId('route-1'),
          amount: 5000,
          currency: 'IQD',
          method: 'zain_cash',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (payInfo) {
            expect(payInfo.id, 'pay-123');
            expect(payInfo.amount, 5000);
            expect(
              payInfo.paymentUrl,
              'https://pay.zaincash.iq/transaction?id=123',
            );
          },
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(
          () => mockRemote.createPayment(
            routeId: 'route-1',
            amount: 5000,
            currency: 'IQD',
            method: 'zain_cash',
          ),
        ).thenThrow(Exception('Payment service offline'));

        final result = await repository.createPayment(
          routeId: const RouteId('route-1'),
          amount: 5000,
          currency: 'IQD',
          method: 'zain_cash',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getPaymentStatus', () {
      test('returns PaymentInfo when found', () async {
        final mockPaymentJson = {
          'id': 'pay-123',
          'amount': 5000,
          'currency': 'IQD',
          'status': 'completed',
          'method': 'zain_cash',
          'payment_url': 'https://pay.zaincash.iq/transaction?id=123',
        };

        when(() => mockRemote.getPaymentStatus('pay-123'))
            .thenAnswer((_) async => mockPaymentJson);

        final result = await repository.getPaymentStatus('pay-123');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (payInfo) {
            expect(payInfo.id, 'pay-123');
            expect(payInfo.status, 'completed');
          },
        );
      });

      test('returns Left(NotFoundFailure) when payment is not found', () async {
        when(() => mockRemote.getPaymentStatus('pay-123'))
            .thenAnswer((_) async => null);

        final result = await repository.getPaymentStatus('pay-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getPaymentStatus('pay-123'))
            .thenThrow(Exception('Fetch payment error'));

        final result = await repository.getPaymentStatus('pay-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getDriverById', () {
      final mockDriverJson = {
        'id': 'driver-123',
        'user_id': 'user-123',
        'vehicle_model': 'KIA Besta',
        'vehicle_plate': 'A123',
        'capacity': 10,
        'is_verified': true,
        'rating': 4.5,
      };

      test('returns Driver on success', () async {
        when(() => mockRemote.getDriverById('driver-123'))
            .thenAnswer((_) async => mockDriverJson);

        final result = await repository.getDriverById(const DriverId('driver-123'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (driver) {
            expect(driver.id, const DriverId('driver-123'));
            expect(driver.vehicleModel, 'KIA Besta');
            expect(driver.rating, 4.5);
          },
        );
      });

      test('returns Left(NotFoundFailure) when not found', () async {
        when(() => mockRemote.getDriverById('driver-123'))
            .thenAnswer((_) async => null);

        final result = await repository.getDriverById(const DriverId('driver-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getDriverProfile', () {
      final mockProfileJson = {
        'id': 'user-123',
        'email': 'driver@sayr.app',
        'role': 'driver',
        'full_name': 'Driver Name',
        'phone': '07901234567',
        'is_verified': true,
        'avatar_url': 'https://avatar',
      };

      test('returns User profile on success', () async {
        when(() => mockRemote.fetchCurrentProfile('user-123'))
            .thenAnswer((_) async => mockProfileJson);

        final result = await repository.getDriverProfile(const UserId('user-123'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (user) {
            expect(user.id, const UserId('user-123'));
            expect(user.fullName, 'Driver Name');
            expect(user.avatarUrl, 'https://avatar');
          },
        );
      });
    });

    group('submitRating', () {
      final mockRatingJson = {
        'id': 'rate-123',
        'trip_id': 'trip-123',
        'student_id': 'student-123',
        'driver_id': 'driver-123',
        'rating': 5,
        'created_at': '2026-06-04T08:00:00Z',
        'comment': 'Great driver',
      };

      test('returns Rating on success when authenticated', () async {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('student-123');
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(() => mockRemote.submitRating(
              tripId: 'trip-123',
              driverId: 'driver-123',
              studentId: 'student-123',
              rating: 5,
              comment: 'Great driver',
            )).thenAnswer((_) async => mockRatingJson);

        final result = await repository.submitRating(
          tripId: const TripId('trip-123'),
          driverId: const DriverId('driver-123'),
          rating: 5,
          comment: 'Great driver',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (rating) {
            expect(rating.id, const RatingId('rate-123'));
            expect(rating.rating, 5);
            expect(rating.comment, 'Great driver');
          },
        );
      });

      test('returns Left(UnauthorizedFailure) when not authenticated', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.submitRating(
          tripId: const TripId('trip-123'),
          driverId: const DriverId('driver-123'),
          rating: 5,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getTripRating', () {
      final mockRatingJson = {
        'id': 'rate-123',
        'trip_id': 'trip-123',
        'student_id': 'student-123',
        'driver_id': 'driver-123',
        'rating': 5,
        'created_at': '2026-06-04T08:00:00Z',
        'comment': 'Great driver',
      };

      test('returns Rating when exists', () async {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('student-123');
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(() => mockRemote.getTripRating(
              tripId: 'trip-123',
              studentId: 'student-123',
            )).thenAnswer((_) async => mockRatingJson);

        final result = await repository.getTripRating(const TripId('trip-123'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (rating) {
            expect(rating, isNotNull);
            expect(rating!.id, const RatingId('rate-123'));
          },
        );
      });

      test('returns null when rating does not exist', () async {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('student-123');
        when(() => mockRemote.currentUser).thenReturn(mockUser);
        when(() => mockRemote.getTripRating(
              tripId: 'trip-123',
              studentId: 'student-123',
            )).thenAnswer((_) async => null);

        final result = await repository.getTripRating(const TripId('trip-123'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (rating) => expect(rating, isNull),
        );
      });
    });
  });
}
