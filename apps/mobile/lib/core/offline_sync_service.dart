import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Service that monitors connectivity and syncs pending locations when online.
@lazySingleton
class OfflineSyncService {
  /// Creates an [OfflineSyncService].
  OfflineSyncService({
    required LocalDatasource localDatasource,
    required TripRepository tripRepository,
    required Talker talker,
    Connectivity? connectivity,
  })  : _localDatasource = localDatasource,
        _tripRepository = tripRepository,
        _talker = talker,
        _connectivity = connectivity ?? Connectivity();

  final LocalDatasource _localDatasource;
  final TripRepository _tripRepository;
  final Connectivity _connectivity;
  final Talker _talker;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;
  bool _syncPending = false;

  /// Start listening to connectivity changes.
  void start() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged
        .debounce(const Duration(seconds: 2))
        .listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        _syncPendingLocations();
      }
    });
  }

  /// Stop listening to connectivity changes.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _syncPendingLocations() async {
    if (_isSyncing) {
      _syncPending = true;
      return;
    }
    _isSyncing = true;
    _syncPending = false;

    try {
      // 1. Sync pending trip statuses first
      final pendingStatuses = await _localDatasource.getPendingTripStatuses();
      if (pendingStatuses.isNotEmpty) {
        _talker.info(
          'OfflineSyncService: Found ${pendingStatuses.length} pending trip statuses. '
          'Syncing...',
        );
        final syncStatusesResult = await _tripRepository.syncPendingStatuses();
        await syncStatusesResult.fold(
          (failure) async {
            _talker.warning(
              'OfflineSyncService: Failed to sync pending trip statuses: '
              '${failure.message}',
            );
          },
          (_) async {
            _talker.info(
              'OfflineSyncService: Successfully synced pending trip statuses.',
            );
          },
        );
      }

      // 2. Sync pending locations
      final pending = await _localDatasource.getPendingLocations();
      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      _talker.info(
        'OfflineSyncService: Found ${pending.length} pending location updates. '
        'Syncing...',
      );

      final locationsToSync = pending
          .map(
            (p) => (
              tripId: TripId(p.tripId),
              lat: p.latitude,
              lng: p.longitude,
            ),
          )
          .toList();

      final result = await _tripRepository.bulkUpdateLocations(locationsToSync);

      await result.fold(
        (failure) async {
          _talker.warning(
            'OfflineSyncService: Failed to sync pending locations: '
            '${failure.message}',
          );
        },
        (syncedLocations) async {
          final successfulIds = <int>[];
          final pendingCopy = List<PendingLocationUpdateData>.from(pending);
          for (final loc in syncedLocations) {
            final matchIndex = pendingCopy.indexWhere(
              (p) =>
                  p.tripId == loc.tripId.value &&
                  p.latitude == loc.lat &&
                  p.longitude == loc.lng,
            );
            if (matchIndex != -1) {
              successfulIds.add(pendingCopy[matchIndex].id);
              pendingCopy.removeAt(matchIndex);
            }
          }

          if (successfulIds.isNotEmpty) {
            await _localDatasource.markLocationsSynced(successfulIds);
            await _localDatasource.cleanupOldLocations();
            await _localDatasource.cleanupOldTripStatuses();
            _talker.info(
              'OfflineSyncService: Successfully synced ${successfulIds.length} '
              'of ${pending.length} location updates.',
            );
          }
        },
      );
    } catch (e, st) {
      _talker.error('OfflineSyncService: Error during synchronization', e, st);
    } finally {
      _isSyncing = false;
      if (_syncPending) {
        scheduleMicrotask(_syncPendingLocations);
      }
    }
  }
}
