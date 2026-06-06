import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

/// Service that monitors connectivity and syncs pending locations when online.
class OfflineSyncService {
  /// Creates an [OfflineSyncService].
  OfflineSyncService({
    required LocalDatasource localDatasource,
    required TripRepository tripRepository,
    Connectivity? connectivity,
  })  : _localDatasource = localDatasource,
        _tripRepository = tripRepository,
        _connectivity = connectivity ?? Connectivity();

  final LocalDatasource _localDatasource;
  final TripRepository _tripRepository;
  final Connectivity _connectivity;
  final Logger _logger = Logger();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  /// Start listening to connectivity changes.
  void start() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        // Wait a brief moment to ensure stable connection
        Future.delayed(const Duration(seconds: 2), _syncPendingLocations);
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

      _logger.i(
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
          _logger.w(
            'OfflineSyncService: Failed to sync pending locations: '
            '${failure.message}',
          );
        },
        (_) async {
          final ids = pending.map((p) => p.id).toList();
          await _localDatasource.markLocationsSynced(ids);
          await _localDatasource.cleanupOldLocations();
          _logger.i(
            'OfflineSyncService: Successfully synced $pendingCount '
            'location updates.',
          );
        },
      );
    } catch (e) {
      _logger.e('OfflineSyncService: Error during synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
