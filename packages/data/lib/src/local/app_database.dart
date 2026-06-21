import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'package:sayr_data/src/local/tables.dart';

part 'app_database.g.dart';

/// Local SQLite database via Drift for offline location queue + caching.
@lazySingleton
@DriftDatabase(
    tables: [PendingLocationUpdate, CachedTrip, CachedRoute, TripStatusQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(tripStatusQueue);
          }
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'sayr');
}
