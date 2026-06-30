import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'package:sayr_data/src/local/tables.dart';

part 'app_database.g.dart';

/// Local SQLite database via Drift for offline location queue + caching.
@LazySingleton(order: -1)
@DriftDatabase(
    tables: [PendingLocationUpdate, CachedTrip, CachedRoute, TripStatusQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(tripStatusQueue);
          }
          if (from < 3) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS pending_location_synced_idx ON pending_location_update (synced);',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS trip_status_queue_synced_idx ON trip_status_queue (synced);',
            );
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'sayr');
}
