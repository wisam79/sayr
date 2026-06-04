import 'package:drift/drift.dart';
import 'package:sayr_core/sayr_core.dart';

import 'app_database.dart';
import 'tables.dart';

/// DAO for offline location queue operations.
class LocationQueueDao {
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
          ..where((t) =>
              t.synced.equals(true) & t.createdAt.isSmallerThanValue(cutoff)))
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
class TripCacheDao {
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
