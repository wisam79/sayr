import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/local/app_database.dart';
import 'package:sayr_data/src/local/location_queue_dao.dart';
import 'package:sayr_data/src/storage/secure_storage.dart';

abstract class LocalDatasource {
  // Secure Storage
  Future<void> setAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> setRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> setUserId(String userId);
  Future<String?> getUserId();
  Future<void> clearSecureStorage();

  // Location Queue
  Future<void> enqueueLocation({
    required String tripId,
    required double latitude,
    required double longitude,
  });
  Future<List<PendingLocationUpdateData>> getPendingLocations();
  Future<void> markLocationsSynced(List<int> ids);
  Future<void> cleanupOldLocations({int daysOld = 7});
  Future<int> getPendingLocationsCount();

  // Trip Cache
  Future<void> cacheTrips(List<Trip> trips);
  Future<List<Trip>> getCachedTrips();
  Future<void> clearCachedTrips();

  // Route Cache
  Future<void> cacheRoutes(List<Route> routes);
  Future<List<Route>> getCachedRoutes();
  Future<void> clearCachedRoutes();

  // Status Queue
  Future<void> enqueueTripStatus({
    required String tripId,
    required String status,
    double? latitude,
    double? longitude,
  });
  Future<List<TripStatusQueueData>> getPendingTripStatuses();
  Future<void> markTripStatusesSynced(List<int> ids);
  Future<void> cleanupOldTripStatuses({int daysOld = 7});
}

@LazySingleton(as: LocalDatasource)
class LocalDatasourceImpl implements LocalDatasource {
  LocalDatasourceImpl({
    SecureStorageService? secureStorage,
    LocationQueueDao? locationQueueDao,
    TripCacheDao? tripCacheDao,
    RouteCacheDao? routeCacheDao,
    TripStatusQueueDao? tripStatusQueueDao,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _locationQueueDao = locationQueueDao ?? LocationQueueDao(),
        _tripCacheDao = tripCacheDao ?? TripCacheDao(),
        _routeCacheDao = routeCacheDao ?? RouteCacheDao(),
        _tripStatusQueueDao = tripStatusQueueDao ?? TripStatusQueueDao();
  final SecureStorageService _secureStorage;
  final LocationQueueDao _locationQueueDao;
  final TripCacheDao _tripCacheDao;
  final RouteCacheDao _routeCacheDao;
  final TripStatusQueueDao _tripStatusQueueDao;

  // Secure Storage
  @override
  Future<void> setAuthToken(String token) => _secureStorage.setAuthToken(token);

  @override
  Future<String?> getAuthToken() => _secureStorage.getAuthToken();

  @override
  Future<void> setRefreshToken(String token) =>
      _secureStorage.setRefreshToken(token);

  @override
  Future<String?> getRefreshToken() => _secureStorage.getRefreshToken();

  @override
  Future<void> setUserId(String userId) => _secureStorage.setUserId(userId);

  @override
  Future<String?> getUserId() => _secureStorage.getUserId();

  @override
  Future<void> clearSecureStorage() => _secureStorage.clear();

  // Location Queue
  @override
  Future<void> enqueueLocation({
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    await _locationQueueDao.enqueue(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<List<PendingLocationUpdateData>> getPendingLocations() =>
      _locationQueueDao.getPending();

  @override
  Future<void> markLocationsSynced(List<int> ids) =>
      _locationQueueDao.markSynced(ids);

  @override
  Future<void> cleanupOldLocations({int daysOld = 7}) =>
      _locationQueueDao.cleanupOld(daysOld: daysOld);

  @override
  Future<int> getPendingLocationsCount() => _locationQueueDao.pendingCount();

  // Trip Cache
  @override
  Future<void> cacheTrips(List<Trip> trips) => _tripCacheDao.cacheTrips(trips);

  @override
  Future<List<Trip>> getCachedTrips() => _tripCacheDao.getCachedTrips();

  @override
  Future<void> clearCachedTrips() => _tripCacheDao.clear();

  // Route Cache
  @override
  Future<void> cacheRoutes(List<Route> routes) =>
      _routeCacheDao.cacheRoutes(routes);

  @override
  Future<List<Route>> getCachedRoutes() => _routeCacheDao.getCachedRoutes();

  @override
  Future<void> clearCachedRoutes() => _routeCacheDao.clear();

  // Status Queue
  @override
  Future<void> enqueueTripStatus({
    required String tripId,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    await _tripStatusQueueDao.enqueue(
      tripId: tripId,
      status: status,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<List<TripStatusQueueData>> getPendingTripStatuses() =>
      _tripStatusQueueDao.getPending();

  @override
  Future<void> markTripStatusesSynced(List<int> ids) =>
      _tripStatusQueueDao.markSynced(ids);

  @override
  Future<void> cleanupOldTripStatuses({int daysOld = 7}) =>
      _tripStatusQueueDao.cleanupOld(daysOld: daysOld);
}
