import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_data/src/models/trip_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:talker_flutter/talker_flutter.dart';

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
      talker: Talker(),
      syncTrigger: BackgroundSyncTrigger(),
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
    final mockTrip = TripModel.fromJson(mockTripJson);

    group('getActiveTrips', () {
      test('returns List<Trip> on success', () async {
        when(() => mockRemote.getActiveTrips())
            .thenAnswer((_) async => [mockTrip]);

        final result = await repository.getActiveTrips();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (data) {
            expect(data.trips.length, 1);
            expect(data.trips.first.id, const TripId('trip-123'));
            expect(data.trips.first.status, TripStatus.scheduled);
            expect(data.fromCache, false);
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
        final controller = StreamController<List<TripModel>>();
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

        controller.add([mockTrip]);

        await controller.close();
      });

      test('throws NotFoundFailure when watch stream is empty', () async {
        final controller = StreamController<List<TripModel>>();
        when(() => mockRemote.watchTrip('trip-123'))
            .thenAnswer((_) => controller.stream);

        final stream = repository.watchTrip(const TripId('trip-123'));

        expect(stream, emitsError(isA<NotFoundFailure>()));

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
            .thenAnswer((_) async => mockTrip);

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
            .thenAnswer((_) async => mockTrip);

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
        when(() => mockLocal.getCachedTripById(const TripId('trip-123')))
            .thenAnswer((_) async => null);

        final result = await repository.getById(const TripId('trip-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });

      test(
          'falls back to local cache when remote throws exception and cached trip exists',
          () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenThrow(Exception('Network issue'));
        when(() => mockLocal.getCachedTripById(const TripId('trip-123')))
            .thenAnswer((_) async => mockTrip.toEntity());

        final result = await repository.getById(const TripId('trip-123'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should fall back to cache'),
          (trip) => expect(trip.id, const TripId('trip-123')),
        );
      });

      test(
          'returns original failure when remote throws exception and cache also throws',
          () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenThrow(Exception('Network issue'));
        when(() => mockLocal.getCachedTripById(const TripId('trip-123')))
            .thenThrow(Exception('Database is locked'));

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
            .thenAnswer((_) async => mockTrip);

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
        ).thenAnswer((_) async => TripModel.fromJson(updatedTripJson));

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
            .thenAnswer((_) async => mockTrip);

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

      test(
          'falls back offline and returns Right(trip) when updateTripStatus throws exception',
          () async {
        when(() => mockRemote.getTripById('trip-123'))
            .thenAnswer((_) async => mockTrip);
        when(() => mockLocal.getCachedTrips()).thenAnswer((_) async => []);
        when(() => mockLocal.cacheTrips(any())).thenAnswer((_) async {});

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

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed offline'),
          (trip) => expect(trip.status, TripStatus.driverWaiting),
        );
      });
    });

    group('updateLocation', () {
      test(
          'calls updateTripLocation on remote datasource and does not enqueue locally on success',
          () async {
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
        verifyNever(
          () => mockLocal.enqueueLocation(
            tripId: any(named: 'tripId'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      });

      test(
          'enqueues location locally and returns Right(unit) when remote throws exception and local enqueue succeeds',
          () async {
        when(
          () => mockRemote.updateTripLocation(
            tripId: 'trip-123',
            lat: 33.123,
            lng: 44.456,
          ),
        ).thenThrow(Exception('Update location failed'));

        when(
          () => mockLocal.enqueueLocation(
            tripId: 'trip-123',
            latitude: 33.123,
            longitude: 44.456,
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
        verify(
          () => mockLocal.enqueueLocation(
            tripId: 'trip-123',
            latitude: 33.123,
            longitude: 44.456,
          ),
        ).called(1);
      });

      test(
          'returns Left(Failure) when remote throws exception and local enqueue also fails',
          () async {
        when(
          () => mockRemote.updateTripLocation(
            tripId: 'trip-123',
            lat: 33.123,
            lng: 44.456,
          ),
        ).thenThrow(Exception('Update location failed'));

        when(
          () => mockLocal.enqueueLocation(
            tripId: 'trip-123',
            latitude: 33.123,
            longitude: 44.456,
          ),
        ).thenThrow(Exception('Database write failed'));

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
        verify(
          () => mockRemote.updateTripLocation(
            tripId: 'trip-123',
            lat: 33.123,
            lng: 44.456,
          ),
        ).called(1);
        verify(
          () => mockLocal.enqueueLocation(
            tripId: 'trip-123',
            latitude: 33.123,
            longitude: 44.456,
          ),
        ).called(1);
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
        when(() => mockRemote.updateTripLocation(
              tripId: any(named: 'tripId'),
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
            )).thenThrow(Exception('Fallback failed'));

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

    group('updateBleOtp', () {
      test('returns Right(unit) on success', () async {
        final expires = DateTime.now().add(const Duration(minutes: 5));
        when(
          () => mockRemote.updateTripBleOtp(
            tripId: 'trip-123',
            otp: '123456',
            expiresAt: expires.toUtc().toIso8601String(),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.updateBleOtp(
          tripId: const TripId('trip-123'),
          otp: '123456',
          expiresAt: expires,
        );

        expect(result.isRight(), true);
        verify(
          () => mockRemote.updateTripBleOtp(
            tripId: 'trip-123',
            otp: '123456',
            expiresAt: expires.toUtc().toIso8601String(),
          ),
        ).called(1);
      });

      test('returns Left(ServerFailure) on remote exception', () async {
        when(
          () => mockRemote.updateTripBleOtp(
            tripId: any(named: 'tripId'),
            otp: any(named: 'otp'),
            expiresAt: any(named: 'expiresAt'),
          ),
        ).thenThrow(Exception('Supabase RPC error'));

        final result = await repository.updateBleOtp(
          tripId: const TripId('trip-123'),
          otp: '123456',
          expiresAt: DateTime.now(),
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('syncPendingStatuses', () {
      test('does nothing when no pending updates exist', () async {
        when(() => mockLocal.getPendingTripStatuses())
            .thenAnswer((_) async => []);

        final result = await repository.syncPendingStatuses();

        expect(result.isRight(), true);
        verify(() => mockLocal.getPendingTripStatuses()).called(1);
        verifyNever(() => mockRemote.updateTripStatus(
              tripId: any(named: 'tripId'),
              newStatus: any(named: 'newStatus'),
              lat: any(named: 'lat'),
              lng: any(named: 'lng'),
            ));
      });

      test('syncs successfully and marks synced in db', () async {
        final pendingUpdate = TripStatusQueueData(
          id: 1,
          tripId: 'trip-123',
          status: 'in_transit',
          latitude: 33,
          longitude: 44,
          createdAt: DateTime.now(),
          synced: false,
        );
        when(() => mockLocal.getPendingTripStatuses())
            .thenAnswer((_) async => <TripStatusQueueData>[pendingUpdate]);

        when(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-123',
            newStatus: 'in_transit',
            lat: 33,
            lng: 44,
          ),
        ).thenAnswer((_) async => mockTrip);
        when(() => mockLocal.markTripStatusesSynced([1]))
            .thenAnswer((_) async {});

        final result = await repository.syncPendingStatuses();

        expect(result.isRight(), true);
        verify(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-123',
            newStatus: 'in_transit',
            lat: 33,
            lng: 44,
          ),
        ).called(1);
        verify(() => mockLocal.markTripStatusesSynced([1])).called(1);
      });

      test('aborts and marks successes on network error', () async {
        final pending1 = TripStatusQueueData(
          id: 1,
          tripId: 'trip-1',
          status: 'driver_waiting',
          createdAt: DateTime.now(),
          synced: false,
        );
        final pending2 = TripStatusQueueData(
          id: 2,
          tripId: 'trip-2',
          status: 'in_transit',
          createdAt: DateTime.now(),
          synced: false,
        );

        when(() => mockLocal.getPendingTripStatuses())
            .thenAnswer((_) async => <TripStatusQueueData>[pending1, pending2]);
        when(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-1',
            newStatus: 'driver_waiting',
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => mockTrip);
        when(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-2',
            newStatus: 'in_transit',
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenThrow(const SocketException('Failed host lookup'));
        when(() => mockLocal.markTripStatusesSynced([1]))
            .thenAnswer((_) async {});

        final result = await repository.syncPendingStatuses();

        expect(result.isLeft(), true);
        verify(() => mockLocal.markTripStatusesSynced([1])).called(1);
      });

      test('skips/marks as synced on permanent validation error', () async {
        final pending = TripStatusQueueData(
          id: 1,
          tripId: 'trip-1',
          status: 'driver_waiting',
          createdAt: DateTime.now(),
          synced: false,
        );
        when(() => mockLocal.getPendingTripStatuses())
            .thenAnswer((_) async => <TripStatusQueueData>[pending]);
        when(
          () => mockRemote.updateTripStatus(
            tripId: 'trip-1',
            newStatus: 'driver_waiting',
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenThrow(Exception('row does not exist'));
        when(() => mockLocal.markTripStatusesSynced([1]))
            .thenAnswer((_) async {});

        final result = await repository.syncPendingStatuses();

        expect(result.isRight(), true);
        verify(() => mockLocal.markTripStatusesSynced([1])).called(1);
      });
    });
  });
}
