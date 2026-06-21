import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:retry/retry.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:workmanager/workmanager.dart';

const String _syncTaskName = 'locationSyncTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // 1. Initialize binding
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Initialize Supabase client
    await SayrSupabase.instance.init();

    // 3. Initialize background dependency injection
    await initBackgroundDependencies();

    final talker = sl<Talker>();
    final localDatasource = sl<LocalDatasource>();
    final tripRepository = sl<TripRepository>();

    try {
      // 1. Sync pending trip statuses first
      final pendingStatuses = await localDatasource.getPendingTripStatuses();
      if (pendingStatuses.isNotEmpty) {
        talker.info(
          'Background Worker: Found ${pendingStatuses.length} pending trip statuses. Syncing...',
        );
        final syncStatusesResult = await tripRepository.syncPendingStatuses();
        syncStatusesResult.fold(
          (failure) => talker.warning(
            'Background Worker: Failed to sync pending trip statuses: ${failure.message}',
          ),
          (_) => talker.info(
            'Background Worker: Successfully synced pending trip statuses.',
          ),
        );
      }

      // 2. Sync pending locations
      final pendingCount = await localDatasource.getPendingLocationsCount();
      if (pendingCount == 0) {
        return true;
      }

      talker.info(
        'Background Worker: Found $pendingCount pending locations. Syncing...',
      );
      final pending = await localDatasource.getPendingLocations();
      final locationsToSync = pending
          .map(
            (p) => (
              tripId: TripId(p.tripId),
              lat: p.latitude,
              lng: p.longitude,
            ),
          )
          .toList();

      final syncedLocations = await retry(
        () async {
          final result = await tripRepository
              .bulkUpdateLocations(locationsToSync)
              .timeout(const Duration(seconds: 30));

          return result.fold(
            (failure) => throw Exception(failure.message),
            (success) => success,
          );
        },
        maxAttempts: 3,
      );

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
        await localDatasource.markLocationsSynced(successfulIds);
        await localDatasource.cleanupOldLocations();
        talker.info(
          'Background Worker: Successfully synced ${successfulIds.length} locations',
        );
      }
      return true;
    } catch (e, st) {
      talker.error('Background Worker: Sync failure/timeout', e, st);
      return false;
    }
  });
}

class BackgroundSyncService {
  static Talker get _talker => sl<Talker>();

  /// Initializes the Workmanager periodic task.
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      await Workmanager().registerPeriodicTask(
        'sayr-location-sync-periodic',
        _syncTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _talker
          .debug('BackgroundSyncService: Workmanager initialized successfully');
    } catch (e, st) {
      _talker.error(
        'BackgroundSyncService: Failed to initialize Workmanager',
        e,
        st,
      );
    }
  }

  /// Triggers a one-off sync task as soon as internet connection is restored.
  static Future<void> triggerOneOffSync() async {
    try {
      final uniqueId =
          'sayr-location-sync-oneoff-${DateTime.now().millisecondsSinceEpoch}';
      await Workmanager().registerOneOffTask(
        uniqueId,
        _syncTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      _talker.debug(
        'BackgroundSyncService: Registered one-off sync task: $uniqueId',
      );
    } catch (e, st) {
      _talker.error(
        'BackgroundSyncService: Failed to register one-off task',
        e,
        st,
      );
    }
  }
}
