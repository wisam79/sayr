import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Service that monitors connectivity and syncs pending locations when online.
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
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingCount = await _localDatasource.getPendingLocationsCount();
      if (pendingCount == 0) {
        _isSyncing = false;
        return;
      }

      _talker.info(
        'OfflineSyncService: Found $pendingCount pending location updates. '
        'Syncing...',
      );
      final pending = await _localDatasource.getPendingLocations();

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
        (_) async {
          final ids = pending.map((p) => p.id).toList();
          await _localDatasource.markLocationsSynced(ids);
          await _localDatasource.cleanupOldLocations();
          _talker.info(
            'OfflineSyncService: Successfully synced $pendingCount '
            'location updates.',
          );
        },
      );
    } catch (e, st) {
      _talker.error('OfflineSyncService: Error during synchronization', e, st);
    } finally {
      _isSyncing = false;
    }
  }
}
