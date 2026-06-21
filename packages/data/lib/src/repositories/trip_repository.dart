import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:retry/retry.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Callback type for triggering background synchronization.
typedef BackgroundSyncTrigger = void Function();

/// Concrete implementation of TripRepository using Remote and Local data sources.
@LazySingleton(as: TripRepository)
class TripRepositoryImpl extends BaseRepository implements TripRepository {
  TripRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
    required super.talker,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;
  final RemoteDatasource _remoteDatasource;
  final LocalDatasource _localDatasource;

  /// Global trigger for background sync, set by the application.
  static BackgroundSyncTrigger? syncTrigger;

  /// Runs [fetch] against the remote source, caches the result on success, and
  /// transparently falls back to the local cache when the network call fails.
  ///
  /// Mirrors the equivalent helper in `RouteRepositoryImpl`: keeps the offline
  /// behaviour in one place while routing failures through [mapException].
  Future<Either<Failure, List<Trip>>> _fetchTripsWithCacheFallback(
    Future<List<Trip>> Function() fetch, {
    required String cacheLogLabel,
  }) async {
    final result = await guard(() async {
      final trips = await fetch();
      try {
        await _localDatasource.cacheTrips(trips);
      } catch (e, st) {
        log.warning(
          'Failed to cache $cacheLogLabel; serving from network only',
          e,
          st,
        );
      }
      return trips;
    });

    return result.fold(
      (failure) async {
        try {
          final cached = await _localDatasource.getCachedTrips();
          if (cached.isNotEmpty) {
            return Right<Failure, List<Trip>>(cached);
          }
        } catch (cacheError, st) {
          log.warning(
            'Failed to read cached $cacheLogLabel during offline fallback',
            cacheError,
            st,
          );
        }
        return Left<Failure, List<Trip>>(failure);
      },
      (trips) async => Right<Failure, List<Trip>>(trips),
    );
  }

  @override
  Future<Either<Failure, List<Trip>>> getActiveTrips() async {
    return _fetchTripsWithCacheFallback(
      () async {
        final response = await _remoteDatasource.getActiveTrips();
        return response.map((model) => model.toEntity()).toList();
      },
      cacheLogLabel: 'active trips',
    );
  }

  @override
  Future<Either<Failure, Trip>> createTrip({
    required RouteId routeId,
    required DateTime scheduledAt,
  }) async {
    return guard(() async {
      final tripId = await _remoteDatasource.createTrip(
        routeId: routeId.value,
        scheduledAt: scheduledAt,
      );
      final response = await _remoteDatasource.getTripById(tripId);
      if (response == null) {
        throw const NotFoundFailure(resource: 'trip');
      }
      return response.toEntity();
    });
  }

  @override
  Stream<Trip> watchTrip(TripId tripId) {
    return _remoteDatasource.watchTrip(tripId.value).map((rows) {
      if (rows.isEmpty) {
        throw const NotFoundFailure(resource: 'trip');
      }
      return rows.first.toEntity();
    });
  }

  @override
  Future<Either<Failure, Trip>> getById(TripId id) async {
    final result = await guard(() async {
      final response = await _remoteDatasource.getTripById(id.value);
      if (response == null) {
        throw const NotFoundFailure(resource: 'trip');
      }
      return response.toEntity();
    });

    return result.fold(
      (failure) async {
        try {
          final cached = await _localDatasource.getCachedTrips();
          final trip = cached.firstWhere((t) => t.id == id);
          return Right<Failure, Trip>(trip);
        } catch (cacheError, st) {
          log.warning(
            'Failed to read cached trip during offline fallback',
            cacheError,
            st,
          );
        }
        return Left<Failure, Trip>(failure);
      },
      (trip) async => Right<Failure, Trip>(trip),
    );
  }

  @override
  Future<Either<Failure, Trip>> updateStatus({
    required TripId tripId,
    required TripEvent event,
    Coordinates? location,
  }) async {
    final current = await getById(tripId);
    return current.fold<Future<Either<Failure, Trip>>>(
      (Failure failure) async => Left<Failure, Trip>(failure),
      (Trip trip) async {
        final newStatus = TripStateMachine.transition(trip.status, event);
        if (newStatus == null) {
          return Left<Failure, Trip>(
            InvalidStateTransitionFailure(
              from: trip.status.name,
              event: event.name,
            ),
          );
        }
        return guard(() async {
          Trip updatedTrip;
          try {
            final response = await retry(
              () => _remoteDatasource.updateTripStatus(
                tripId: tripId.value,
                newStatus: _statusToDb(newStatus),
                lat: location?.latitude,
                lng: location?.longitude,
              ),
              maxAttempts: 3,
            );
            updatedTrip = response.toEntity();
            try {
              final cached =
                  List<Trip>.from(await _localDatasource.getCachedTrips());
              final index = cached.indexWhere((t) => t.id == tripId);
              if (index != -1) {
                cached[index] = updatedTrip;
              } else {
                cached.add(updatedTrip);
              }
              await _localDatasource.cacheTrips(cached);
            } catch (cacheErr, st) {
              log.warning(
                  'Failed to update local cache on status change success',
                  cacheErr,
                  st);
            }
          } catch (remoteErr) {
            try {
              await _localDatasource.enqueueTripStatus(
                tripId: tripId.value,
                status: _statusToDb(newStatus),
                latitude: location?.latitude,
                longitude: location?.longitude,
              );
              final cached =
                  List<Trip>.from(await _localDatasource.getCachedTrips());
              final index = cached.indexWhere((t) => t.id == tripId);
              if (index != -1) {
                final oldTrip = cached[index];
                updatedTrip = oldTrip.copyWith(
                  status: newStatus,
                  lastLocation: location ?? oldTrip.lastLocation,
                  startedAt: newStatus == TripStatus.inTransit
                      ? DateTime.now()
                      : oldTrip.startedAt,
                  endedAt: (newStatus == TripStatus.completed ||
                          newStatus == TripStatus.cancelled)
                      ? DateTime.now()
                      : oldTrip.endedAt,
                );
                cached[index] = updatedTrip;
                await _localDatasource.cacheTrips(cached);
              } else {
                updatedTrip = trip.copyWith(
                  status: newStatus,
                  lastLocation: location ?? trip.lastLocation,
                  startedAt: newStatus == TripStatus.inTransit
                      ? DateTime.now()
                      : trip.startedAt,
                  endedAt: (newStatus == TripStatus.completed ||
                          newStatus == TripStatus.cancelled)
                      ? DateTime.now()
                      : trip.endedAt,
                );
                await _localDatasource.cacheTrips([...cached, updatedTrip]);
              }
              syncTrigger?.call();
            } catch (cacheErr, st) {
              log.warning(
                  'Failed to update local cache during offline fallback',
                  cacheErr,
                  st);
              updatedTrip = trip.copyWith(
                status: newStatus,
                lastLocation: location ?? trip.lastLocation,
              );
            }
          }
          return updatedTrip;
        });
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> updateLocation({
    required TripId tripId,
    required double lat,
    required double lng,
  }) async {
    final result = await guard(() async {
      await _remoteDatasource.updateTripLocation(
        tripId: tripId.value,
        lat: lat,
        lng: lng,
      );
      return unit;
    });

    return result.fold(
      (failure) async {
        try {
          await _localDatasource.enqueueLocation(
            tripId: tripId.value,
            latitude: lat,
            longitude: lng,
          );
          syncTrigger?.call();
          return const Right<Failure, Unit>(unit);
        } catch (dbErr) {
          // If queueing fails, we log it via the returned mapped exception,
          // but we still want to map it to Failure properly.
          return Left<Failure, Unit>(mapException(dbErr));
        }
      },
      (success) async => Right<Failure, Unit>(success),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateBleOtp({
    required TripId tripId,
    required String otp,
    required DateTime expiresAt,
  }) async {
    return guard(() async {
      await _remoteDatasource.updateTripBleOtp(
        tripId: tripId.value,
        otp: otp,
        expiresAt: expiresAt.toUtc().toIso8601String(),
      );
      return unit;
    });
  }

  @override
  Future<
      Either<
          Failure,
          List<
              ({
                TripId tripId,
                double lat,
                double lng,
              })>>> bulkUpdateLocations(
    List<
            ({
              TripId tripId,
              double lat,
              double lng,
            })>
        locations,
  ) async {
    return guard(() async {
      final locationsJson = locations
          .map(
            (l) => {
              'trip_id': l.tripId.value,
              'lat': l.lat,
              'lng': l.lng,
            },
          )
          .toList();

      try {
        await _remoteDatasource.bulkUpdateTripLocations(locationsJson);
        return locations;
      } catch (e) {
        final successful = <({TripId tripId, double lat, double lng})>[];
        Object? lastError;
        for (final loc in locations) {
          try {
            await _remoteDatasource.updateTripLocation(
              tripId: loc.tripId.value,
              lat: loc.lat,
              lng: loc.lng,
            );
            successful.add(loc);
          } catch (individualErr) {
            log.warning(
              'Failed to sync location for trip ${loc.tripId.value} during fallback: $individualErr',
            );
            lastError = individualErr;
          }
        }
        if (successful.isNotEmpty) {
          return successful;
        }
        if (lastError != null) {
          if (lastError is Exception) {
            throw lastError;
          }
          if (lastError is Error) {
            throw lastError;
          }
          throw Exception(lastError.toString());
        }
        rethrow;
      }
    });
  }

  String _statusToDb(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.driverWaiting:
        return 'driver_waiting';
      case TripStatus.inTransit:
        return 'in_transit';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.absent:
        return 'absent';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  @override
  Future<Either<Failure, Unit>> syncPendingStatuses() async {
    return guard(() async {
      final pending = await _localDatasource.getPendingTripStatuses();
      if (pending.isEmpty) {
        return unit;
      }

      final syncedIds = <int>[];
      final failedIds = <int>[];
      for (final statusUpdate in pending) {
        try {
          await _remoteDatasource.updateTripStatus(
            tripId: statusUpdate.tripId,
            newStatus: statusUpdate.status,
            lat: statusUpdate.latitude,
            lng: statusUpdate.longitude,
          );
          syncedIds.add(statusUpdate.id);
        } catch (e) {
          final isNetworkError = e is SocketException ||
              e is HttpException ||
              e is TimeoutException ||
              e.toString().contains('SocketException') ||
              e.toString().contains('HttpException') ||
              e.toString().contains('TimeoutException');

          if (isNetworkError) {
            // Transient network failure: save what succeeded so far and abort sync.
            if (syncedIds.isNotEmpty) {
              await _localDatasource.markTripStatusesSynced(syncedIds);
            }
            if (failedIds.isNotEmpty) {
              await _localDatasource.markTripStatusesSynced(failedIds);
            }
            rethrow;
          } else {
            // Permanent validation/logic failure: log it, skip it (so we don't try it forever),
            // and add to failedIds to mark as synced/deleted.
            log.error(
              'syncPendingStatuses: Permanent failure for status update ${statusUpdate.id} (trip: ${statusUpdate.tripId}). Skipping.',
              e,
            );
            failedIds.add(statusUpdate.id);
          }
        }
      }

      final allMarked = [...syncedIds, ...failedIds];
      if (allMarked.isNotEmpty) {
        await _localDatasource.markTripStatusesSynced(allMarked);
      }
      return unit;
    });
  }
}
