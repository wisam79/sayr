import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/local/app_database.dart';
import 'package:sayr_data/src/local/location_queue_dao.dart';
import 'package:sayr_data/src/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorageService {}

class MockLocationQueueDao extends Mock implements LocationQueueDao {}

class MockTripCacheDao extends Mock implements TripCacheDao {}

class MockRouteCacheDao extends Mock implements RouteCacheDao {}

class MockTripStatusQueueDao extends Mock implements TripStatusQueueDao {}

class FakeTrip extends Fake implements Trip {}

class FakeRoute extends Fake implements Route {}

class FakePendingLocation extends Fake implements PendingLocationUpdateData {}

void main() {
  late MockSecureStorage mockSecureStorage;
  late MockLocationQueueDao mockLocationQueueDao;
  late MockTripCacheDao mockTripCacheDao;
  late MockRouteCacheDao mockRouteCacheDao;
  late MockTripStatusQueueDao mockTripStatusQueueDao;
  late LocalDatasourceImpl datasource;

  setUpAll(() {
    registerFallbackValue(FakeTrip());
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    mockLocationQueueDao = MockLocationQueueDao();
    mockTripCacheDao = MockTripCacheDao();
    mockRouteCacheDao = MockRouteCacheDao();
    mockTripStatusQueueDao = MockTripStatusQueueDao();

    datasource = LocalDatasourceImpl(
      secureStorage: mockSecureStorage,
      locationQueueDao: mockLocationQueueDao,
      tripCacheDao: mockTripCacheDao,
      routeCacheDao: mockRouteCacheDao,
      tripStatusQueueDao: mockTripStatusQueueDao,
    );
  });

  group('LocalDatasourceImpl', () {
    test('setAuthToken calls secure storage', () async {
      when(() => mockSecureStorage.setAuthToken('token'))
          .thenAnswer((_) async {});
      await datasource.setAuthToken('token');
      verify(() => mockSecureStorage.setAuthToken('token')).called(1);
    });

    test('getAuthToken calls secure storage', () async {
      when(() => mockSecureStorage.getAuthToken())
          .thenAnswer((_) async => 'token');
      final result = await datasource.getAuthToken();
      expect(result, equals('token'));
      verify(() => mockSecureStorage.getAuthToken()).called(1);
    });

    test('enqueueLocation calls dao', () async {
      when(
        () => mockLocationQueueDao.enqueue(
          tripId: 'trip1',
          latitude: 1,
          longitude: 2,
        ),
      ).thenAnswer((_) async {});

      await datasource.enqueueLocation(
          tripId: 'trip1', latitude: 1, longitude: 2);

      verify(
        () => mockLocationQueueDao.enqueue(
          tripId: 'trip1',
          latitude: 1,
          longitude: 2,
        ),
      ).called(1);
    });

    test('getPendingLocations calls dao', () async {
      final fakeData = FakePendingLocation();
      when(() => mockLocationQueueDao.getPending())
          .thenAnswer((_) async => [fakeData]);

      final result = await datasource.getPendingLocations();

      expect(result, equals([fakeData]));
      verify(() => mockLocationQueueDao.getPending()).called(1);
    });

    test('markLocationsSynced calls dao', () async {
      when(() => mockLocationQueueDao.markSynced([1, 2]))
          .thenAnswer((_) async {});

      await datasource.markLocationsSynced([1, 2]);

      verify(() => mockLocationQueueDao.markSynced([1, 2])).called(1);
    });

    test('cacheTrips calls dao', () async {
      final trip = FakeTrip();
      when(() => mockTripCacheDao.cacheTrips([trip])).thenAnswer((_) async {});

      await datasource.cacheTrips([trip]);

      verify(() => mockTripCacheDao.cacheTrips([trip])).called(1);
    });

    test('getCachedTrips calls dao', () async {
      final trip = FakeTrip();
      when(() => mockTripCacheDao.getCachedTrips())
          .thenAnswer((_) async => [trip]);

      final result = await datasource.getCachedTrips();

      expect(result, equals([trip]));
      verify(() => mockTripCacheDao.getCachedTrips()).called(1);
    });

    test('clearCachedTrips calls dao', () async {
      when(() => mockTripCacheDao.clear()).thenAnswer((_) async {});

      await datasource.clearCachedTrips();

      verify(() => mockTripCacheDao.clear()).called(1);
    });
  });
}
