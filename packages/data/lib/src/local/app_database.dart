import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:sayr_data/src/local/tables.dart';

part 'app_database.g.dart';

/// Local SQLite database via Drift for offline location queue + caching.
@DriftDatabase(tables: [PendingLocationUpdate, CachedTrip, CachedRoute])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'sayr');
}
