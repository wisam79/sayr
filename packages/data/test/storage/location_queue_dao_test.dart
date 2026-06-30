import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/local/app_database.dart';
import 'package:sayr_data/src/local/location_queue_dao.dart';

void main() {
  late AppDatabase db;
  late LocationQueueDao locationQueueDao;
  late TripCacheDao tripCacheDao;
  late RouteCacheDao routeCacheDao;
  late TripStatusQueueDao tripStatusQueueDao;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    locationQueueDao = LocationQueueDao(db: db);
    tripCacheDao = TripCacheDao(db: db);
    routeCacheDao = RouteCacheDao(db: db);
    tripStatusQueueDao = TripStatusQueueDao(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LocationQueueDao', () {
    test('enqueues and retrieves pending updates, counts and marks synced',
        () async {
      var count = await locationQueueDao.pendingCount();
      expect(count, 0);

      await locationQueueDao.enqueue(
        tripId: 'trip-1',
        latitude: 33.3,
        longitude: 44.4,
      );

      count = await locationQueueDao.pendingCount();
      expect(count, 1);

      final pending = await locationQueueDao.getPending();
      expect(pending.length, 1);
      expect(pending.first.tripId, 'trip-1');
      expect(pending.first.latitude, 33.3);
      expect(pending.first.longitude, 44.4);
      expect(pending.first.synced, false);

      final id = pending.first.id;
      await locationQueueDao.markSynced([id]);

      count = await locationQueueDao.pendingCount();
      expect(count, 0);

      final pendingAfter = await locationQueueDao.getPending();
      expect(pendingAfter.isEmpty, true);
    });

    test('cleans up old synced entries', () async {
      await db.into(db.pendingLocationUpdate).insert(
            PendingLocationUpdateCompanion.insert(
              tripId: 'trip-1',
              latitude: 33.3,
              longitude: 44.4,
              createdAt:
                  Value(DateTime.now().subtract(const Duration(days: 8))),
              synced: const Value(true),
            ),
          );

      // Cleanup with 7 days old should clean it up
      await locationQueueDao.cleanupOld(daysOld: 7);

      // Verify it's gone
      final count = await db.select(db.pendingLocationUpdate).get();
      expect(count.isEmpty, true);
    });
  });

  group('TripCacheDao', () {
    final testTrip = Trip(
      id: const TripId('trip-1'),
      routeId: const RouteId('route-1'),
      driverId: const DriverId('driver-1'),
      status: TripStatus.inTransit,
      scheduledAt: DateTime.parse('2026-06-04T08:00:00.000Z'),
      startedAt: DateTime.parse('2026-06-04T08:05:00.000Z'),
      endedAt: DateTime.parse('2026-06-04T08:45:00.000Z'),
      lastLocation: Coordinates(latitude: 33.3, longitude: 44.4),
    );

    test('caches, retrieves, updates and clears trips', () async {
      var cached = await tripCacheDao.getCachedTrips();
      expect(cached.isEmpty, true);

      await tripCacheDao.cacheTrips([testTrip]);

      cached = await tripCacheDao.getCachedTrips();
      expect(cached.length, 1);
      expect(cached.first.id, const TripId('trip-1'));
      expect(cached.first.status, TripStatus.inTransit);

      final single =
          await tripCacheDao.getCachedTripById(const TripId('trip-1'));
      expect(single, isNotNull);
      expect(single!.id, const TripId('trip-1'));

      final updatedTrip = testTrip.copyWith(status: TripStatus.completed);
      await tripCacheDao.upsertCachedTrip(updatedTrip);

      final singleUpdated =
          await tripCacheDao.getCachedTripById(const TripId('trip-1'));
      expect(singleUpdated!.status, TripStatus.completed);

      await tripCacheDao.clear();
      cached = await tripCacheDao.getCachedTrips();
      expect(cached.isEmpty, true);
    });
  });

  group('RouteCacheDao', () {
    final testRoute = Route(
      id: const RouteId('route-1'),
      driverId: const DriverId('driver-1'),
      title: 'Baghdad Route',
      startLocation: 'Start',
      endLocation: 'End',
      price: const Money(50000),
      capacity: 30,
      availableSeats: 10,
      isActive: true,
      startCoordinates: Coordinates(latitude: 33.1, longitude: 44.1),
      endCoordinates: Coordinates(latitude: 33.2, longitude: 44.2),
      departureTime: '08:00',
      returnTime: '16:00',
    );

    test('caches, retrieves, and clears routes', () async {
      var cached = await routeCacheDao.getCachedRoutes();
      expect(cached.isEmpty, true);

      await routeCacheDao.cacheRoutes([testRoute]);

      cached = await routeCacheDao.getCachedRoutes();
      expect(cached.length, 1);
      expect(cached.first.id, const RouteId('route-1'));
      expect(cached.first.title, 'Baghdad Route');

      await routeCacheDao.clear();
      cached = await routeCacheDao.getCachedRoutes();
      expect(cached.isEmpty, true);
    });
  });

  group('TripStatusQueueDao', () {
    test('enqueues, retrieves, and marks synced status updates', () async {
      var pending = await tripStatusQueueDao.getPending();
      expect(pending.isEmpty, true);

      await tripStatusQueueDao.enqueue(
        tripId: 'trip-1',
        status: 'in_transit',
        latitude: 33.3,
        longitude: 44.4,
      );

      pending = await tripStatusQueueDao.getPending();
      expect(pending.length, 1);
      expect(pending.first.tripId, 'trip-1');
      expect(pending.first.status, 'in_transit');
      expect(pending.first.latitude, 33.3);
      expect(pending.first.longitude, 44.4);
      expect(pending.first.synced, false);

      final id = pending.first.id;
      await tripStatusQueueDao.markSynced([id]);

      pending = await tripStatusQueueDao.getPending();
      expect(pending.isEmpty, true);
    });

    test('cleans up old synced entries', () async {
      await db.into(db.tripStatusQueue).insert(
            TripStatusQueueCompanion.insert(
              tripId: 'trip-1',
              status: 'in_transit',
              createdAt:
                  Value(DateTime.now().subtract(const Duration(days: 8))),
              synced: const Value(true),
            ),
          );

      await tripStatusQueueDao.cleanupOld(daysOld: 7);

      final count = await db.select(db.tripStatusQueue).get();
      expect(count.isEmpty, true);
    });
  });
}
