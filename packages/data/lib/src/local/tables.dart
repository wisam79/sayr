import 'package:drift/drift.dart';

/// Queued location updates to be synced when back online.
class PendingLocationUpdate extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

/// Cached trip data for offline display.
class CachedTrip extends Table {
  TextColumn get id => text()();
  TextColumn get routeId => text()();
  TextColumn get driverId => text()();
  TextColumn get status => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get lastLat => real().nullable()();
  RealColumn get lastLng => real().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached route data for offline display.
class CachedRoute extends Table {
  TextColumn get id => text()();
  TextColumn get driverId => text()();
  TextColumn get title => text()();
  TextColumn get startLocation => text()();
  TextColumn get endLocation => text()();
  IntColumn get priceAmount => integer()();
  TextColumn get priceCurrency => text().withDefault(const Constant('IQD'))();
  IntColumn get capacity => integer()();
  IntColumn get availableSeats => integer()();
  BoolColumn get isActive => boolean()();
  RealColumn get startLat => real().nullable()();
  RealColumn get startLng => real().nullable()();
  RealColumn get endLat => real().nullable()();
  RealColumn get endLng => real().nullable()();
  TextColumn get departureTime => text().nullable()();
  TextColumn get returnTime => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
