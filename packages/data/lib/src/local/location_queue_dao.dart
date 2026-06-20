import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_data/src/local/app_database.dart';

/// DAO for offline location queue operations.
@lazySingleton
class LocationQueueDao {
  /// Creates a [LocationQueueDao].
  LocationQueueDao({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  /// Insert a location update into the pending queue.
  Future<void> enqueue({
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    await _db.into(_db.pendingLocationUpdate).insert(
          PendingLocationUpdateCompanion.insert(
            tripId: tripId,
            latitude: latitude,
            longitude: longitude,
          ),
        );
  }

  /// Get all unsynced location updates.
  Future<List<PendingLocationUpdateData>> getPending() async {
    return (_db.select(_db.pendingLocationUpdate)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Mark updates as synced after successful upload.
  Future<void> markSynced(List<int> ids) async {
    await (_db.update(_db.pendingLocationUpdate)..where((t) => t.id.isIn(ids)))
        .write(const PendingLocationUpdateCompanion(synced: Value(true)));
  }

  /// Delete old synced entries (older than [daysOld]).
  Future<void> cleanupOld({int daysOld = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    await (_db.delete(_db.pendingLocationUpdate)
          ..where(
            (t) =>
                t.synced.equals(true) & t.createdAt.isSmallerThanValue(cutoff),
          ))
        .go();
  }

  /// Number of pending (unsynced) updates.
  Future<int> pendingCount() async {
    final count = _db.pendingLocationUpdate.id.count();
    final query = _db.selectOnly(_db.pendingLocationUpdate)
      ..addColumns([count])
      ..where(_db.pendingLocationUpdate.synced.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}

/// DAO for cached trip data.
@lazySingleton
class TripCacheDao {
  /// Creates a [TripCacheDao].
  TripCacheDao({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  /// Cache a list of trips.
  Future<void> cacheTrips(List<Trip> trips) async {
    await _db.batch((batch) {
      batch.insertAll(
        _db.cachedTrip,
        trips.map(_tripToCompanion),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Get all cached trips.
  Future<List<Trip>> getCachedTrips() async {
    final rows = await _db.select(_db.cachedTrip).get();
    return rows.map(_rowToTrip).toList();
  }

  /// Clear all cached trips.
  Future<void> clear() async {
    await _db.delete(_db.cachedTrip).go();
  }

  CachedTripCompanion _tripToCompanion(Trip trip) {
    return CachedTripCompanion.insert(
      id: trip.id.value,
      routeId: trip.routeId.value,
      driverId: trip.driverId.value,
      status: trip.status.name,
      scheduledAt: trip.scheduledAt,
      startedAt: Value(trip.startedAt),
      endedAt: Value(trip.endedAt),
      lastLat: Value(trip.lastLocation?.latitude),
      lastLng: Value(trip.lastLocation?.longitude),
    );
  }

  Trip _rowToTrip(CachedTripData row) {
    return Trip(
      id: TripId(row.id),
      routeId: RouteId(row.routeId),
      driverId: DriverId(row.driverId),
      status: TripStatus.fromString(row.status),
      scheduledAt: row.scheduledAt,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      lastLocation: (row.lastLat != null && row.lastLng != null)
          ? Coordinates(
              latitude: row.lastLat!,
              longitude: row.lastLng!,
            )
          : null,
    );
  }
}

/// DAO for cached route data.
@lazySingleton
class RouteCacheDao {
  /// Creates a [RouteCacheDao].
  RouteCacheDao({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  /// Cache a list of routes.
  Future<void> cacheRoutes(List<Route> routes) async {
    await _db.batch((batch) {
      batch.insertAll(
        _db.cachedRoute,
        routes.map(_routeToCompanion),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Get all cached routes.
  Future<List<Route>> getCachedRoutes() async {
    final rows = await _db.select(_db.cachedRoute).get();
    return rows.map(_rowToRoute).toList();
  }

  /// Clear all cached routes.
  Future<void> clear() async {
    await _db.delete(_db.cachedRoute).go();
  }

  CachedRouteCompanion _routeToCompanion(Route route) {
    return CachedRouteCompanion.insert(
      id: route.id.value,
      driverId: route.driverId.value,
      title: route.title,
      startLocation: route.startLocation,
      endLocation: route.endLocation,
      priceAmount: route.price.inIQD,
      priceCurrency: const Value('IQD'),
      capacity: route.capacity,
      availableSeats: route.availableSeats,
      isActive: route.isActive,
      startLat: Value(route.startCoordinates?.latitude),
      startLng: Value(route.startCoordinates?.longitude),
      endLat: Value(route.endCoordinates?.latitude),
      endLng: Value(route.endCoordinates?.longitude),
      departureTime: Value(route.departureTime),
      returnTime: Value(route.returnTime),
    );
  }

  Route _rowToRoute(CachedRouteData row) {
    return Route(
      id: RouteId(row.id),
      driverId: DriverId(row.driverId),
      title: row.title,
      startLocation: row.startLocation,
      endLocation: row.endLocation,
      price: Money(row.priceAmount),
      capacity: row.capacity,
      availableSeats: row.availableSeats,
      isActive: row.isActive,
      startCoordinates: (row.startLat != null && row.startLng != null)
          ? Coordinates(latitude: row.startLat!, longitude: row.startLng!)
          : null,
      endCoordinates: (row.endLat != null && row.endLng != null)
          ? Coordinates(latitude: row.endLat!, longitude: row.endLng!)
          : null,
      departureTime: row.departureTime,
      returnTime: row.returnTime,
    );
  }
}

/// DAO for offline trip status queue operations.
@lazySingleton
class TripStatusQueueDao {
  /// Creates a [TripStatusQueueDao].
  TripStatusQueueDao({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  /// Insert a trip status update into the pending queue.
  Future<void> enqueue({
    required String tripId,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    await _db.into(_db.tripStatusQueue).insert(
          TripStatusQueueCompanion.insert(
            tripId: tripId,
            status: status,
            latitude: Value(latitude),
            longitude: Value(longitude),
          ),
        );
  }

  /// Get all unsynced trip status updates.
  Future<List<TripStatusQueueData>> getPending() async {
    return (_db.select(_db.tripStatusQueue)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Mark status updates as synced.
  Future<void> markSynced(List<int> ids) async {
    await (_db.update(_db.tripStatusQueue)..where((t) => t.id.isIn(ids)))
        .write(const TripStatusQueueCompanion(synced: Value(true)));
  }

  /// Delete old synced entries (older than [daysOld]).
  Future<void> cleanupOld({int daysOld = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    await (_db.delete(_db.tripStatusQueue)
          ..where(
            (t) =>
                t.synced.equals(true) & t.createdAt.isSmallerThanValue(cutoff),
          ))
        .go();
  }
}
