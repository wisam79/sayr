import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

void main() {
  late DriverRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    registerFallbackValue(const DriverId('driver-1'));

    repository = DriverRepositoryImpl(
      remoteDatasource: mockRemote,
      talker: Talker(),
    );
  });

  const driverId = DriverId('driver-1');

  group('DriverRepositoryImpl', () {
    group('getDriverById', () {
      test('returns Driver on success', () async {
        when(() => mockRemote.getDriverById('driver-1')).thenAnswer(
          (_) async => {
            'id': 'driver-1',
            'user_id': 'user-1',
            'vehicle_model': 'Toyota HiAce',
            'vehicle_plate': 'B 12345',
            'capacity': 14,
            'is_verified': true,
            'rating': 4.5,
          },
        );

        final result = await repository.getDriverById(driverId);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (driver) {
            expect(driver.id.value, 'driver-1');
            expect(driver.userId.value, 'user-1');
            expect(driver.vehicleModel, 'Toyota HiAce');
            expect(driver.vehiclePlate, 'B 12345');
            expect(driver.capacity, 14);
            expect(driver.isVerified, isTrue);
            expect(driver.rating, 4.5);
          },
        );
      });

      test('returns NotFoundFailure when driver is null', () async {
        when(() => mockRemote.getDriverById('driver-1'))
            .thenAnswer((_) async => null);

        final result = await repository.getDriverById(driverId);

        expect(result.isLeft(), isTrue);
        expect(
          result.fold((f) => f, (_) => null),
          isA<NotFoundFailure>(),
        );
      });

      test('returns Failure when datasource throws', () async {
        when(() => mockRemote.getDriverById('driver-1'))
            .thenThrow(Exception('network down'));

        final result = await repository.getDriverById(driverId);

        expect(result.isLeft(), isTrue);
      });

      test('uses defaults for missing optional fields', () async {
        when(() => mockRemote.getDriverById('driver-1')).thenAnswer(
          (_) async => {
            'id': 'driver-1',
            'user_id': 'user-1',
            'vehicle_model': 'Bus',
            'vehicle_plate': 'X 1',
            'capacity': 10,
          },
        );

        final result = await repository.getDriverById(driverId);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (driver) {
            expect(driver.isVerified, isFalse);
            expect(driver.rating, 0.0);
          },
        );
      });
    });

    group('getDriverProfile', () {
      test('returns User on success', () async {
        when(() => mockRemote.fetchCurrentProfile('user-1')).thenAnswer(
          (_) async => {
            'id': 'user-1',
            'email': 'driver@example.com',
            'full_name': 'Ahmed Driver',
            'phone': '07700000000',
            'role': 'driver',
            'created_at': '2026-06-01T00:00:00Z',
          },
        );

        final result =
            await repository.getDriverProfile(const UserId('user-1'));

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (user) {
            expect(user.id.value, 'user-1');
            expect(user.fullName, 'Ahmed Driver');
          },
        );
      });

      test('returns NotFoundFailure when profile is null', () async {
        when(() => mockRemote.fetchCurrentProfile('user-1'))
            .thenAnswer((_) async => null);

        final result =
            await repository.getDriverProfile(const UserId('user-1'));

        expect(result.isLeft(), isTrue);
        expect(
          result.fold((f) => f, (_) => null),
          isA<NotFoundFailure>(),
        );
      });
    });
  });
}
