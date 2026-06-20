import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/core/offline_sync_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}

class MockTripRepository extends Mock implements TripRepository {}

class MockTalker extends Mock implements Talker {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockLocalDatasource mockLocal;
  late MockTripRepository mockTripRepo;
  late MockTalker mockTalker;
  late MockConnectivity mockConnectivity;
  late OfflineSyncService service;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    mockLocal = MockLocalDatasource();
    mockTripRepo = MockTripRepository();
    mockTalker = MockTalker();
    mockConnectivity = MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);

    when(() => mockTalker.info(any<dynamic>())).thenAnswer((_) {});
    when(() => mockTalker.warning(any<dynamic>())).thenAnswer((_) {});
    when(
      () => mockTalker.error(
        any<dynamic>(),
        any<Object?>(),
        any<StackTrace?>(),
      ),
    ).thenAnswer((_) {});

    when(() => mockLocal.getPendingTripStatuses())
        .thenAnswer((_) async => const []);
    when(() => mockTripRepo.syncPendingStatuses())
        .thenAnswer((_) async => const Right(unit));

    service = OfflineSyncService(
      localDatasource: mockLocal,
      tripRepository: mockTripRepo,
      talker: mockTalker,
      connectivity: mockConnectivity,
    );
  });

  tearDown(() {
    connectivityController.close();
    service.stop();
  });

  group('OfflineSyncService', () {
    test('start listens to connectivity and stop cancels subscription',
        () async {
      service.start();
      expect(connectivityController.hasListener, isTrue);

      service.stop();
      expect(connectivityController.hasListener, isFalse);
    });

    test('does not sync when pending count is 0', () async {
      when(() => mockLocal.getPendingLocationsCount())
          .thenAnswer((_) async => 0);

      // Trigger sync manually via connectivity update (has connection)
      service.start();
      connectivityController.add([ConnectivityResult.wifi]);

      // Wait for debounce and async operations
      await Future<void>.delayed(const Duration(seconds: 3));

      verify(() => mockLocal.getPendingLocationsCount()).called(1);
      verifyNever(() => mockLocal.getPendingLocations());
      verifyNever(
        () => mockTripRepo.bulkUpdateLocations(
          any<List<({TripId tripId, double lat, double lng})>>(),
        ),
      );
    });

    test(
        'syncs successfully when pending locations exist and repo returns success',
        () async {
      final now = DateTime.now();
      final pendingUpdates = [
        PendingLocationUpdateData(
          id: 10,
          tripId: 'trip-123',
          latitude: 33.3123,
          longitude: 44.3654,
          createdAt: now,
          synced: false,
        ),
        PendingLocationUpdateData(
          id: 11,
          tripId: 'trip-123',
          latitude: 33.3125,
          longitude: 44.3656,
          createdAt: now,
          synced: false,
        ),
      ];

      when(() => mockLocal.getPendingLocationsCount())
          .thenAnswer((_) async => 2);
      when(() => mockLocal.getPendingLocations())
          .thenAnswer((_) async => pendingUpdates);
      when(() => mockLocal.markLocationsSynced(any<List<int>>()))
          .thenAnswer((_) async {});
      when(() => mockLocal.cleanupOldLocations()).thenAnswer((_) async {});

      when(
        () => mockTripRepo.bulkUpdateLocations(
          any<List<({TripId tripId, double lat, double lng,})>>(),
        ),
      ).thenAnswer(
        (invocation) async => Right(
          invocation.positionalArguments[0]
              as List<({TripId tripId, double lat, double lng,})>,
        ),
      );

      service.start();
      connectivityController.add([ConnectivityResult.mobile]);

      await Future<void>.delayed(const Duration(seconds: 3));

      verify(() => mockLocal.getPendingLocationsCount()).called(1);
      verify(() => mockLocal.getPendingLocations()).called(1);

      // Capture the argument passed to bulkUpdateLocations
      final captured =
          verify(() => mockTripRepo.bulkUpdateLocations(captureAny())).captured;
      final locations =
          captured.first as List<({TripId tripId, double lat, double lng})>;
      expect(locations.length, 2);
      expect(locations[0].tripId.value, 'trip-123');
      expect(locations[0].lat, 33.3123);
      expect(locations[0].lng, 44.3654);

      verify(() => mockLocal.markLocationsSynced([10, 11])).called(1);
      verify(() => mockLocal.cleanupOldLocations()).called(1);
    });

    test('stops and warns when repo returns failure', () async {
      final now = DateTime.now();
      final pendingUpdates = [
        PendingLocationUpdateData(
          id: 20,
          tripId: 'trip-555',
          latitude: 33,
          longitude: 44,
          createdAt: now,
          synced: false,
        ),
      ];

      when(() => mockLocal.getPendingLocationsCount())
          .thenAnswer((_) async => 1);
      when(() => mockLocal.getPendingLocations())
          .thenAnswer((_) async => pendingUpdates);
      when(
        () => mockTripRepo.bulkUpdateLocations(
          any<List<({TripId tripId, double lat, double lng})>>(),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server unreachable')),
      );

      service.start();
      connectivityController.add([ConnectivityResult.wifi]);

      await Future<void>.delayed(const Duration(seconds: 3));

      verify(() => mockLocal.getPendingLocationsCount()).called(1);
      verify(() => mockLocal.getPendingLocations()).called(1);
      verify(
        () => mockTripRepo.bulkUpdateLocations(
          any<List<({TripId tripId, double lat, double lng})>>(),
        ),
      ).called(1);

      // Should not mark synced or clean up
      verifyNever(() => mockLocal.markLocationsSynced(any<List<int>>()));
      verifyNever(() => mockLocal.cleanupOldLocations());
      verify(() => mockTalker.warning(any<dynamic>())).called(1);
    });
  });
}
