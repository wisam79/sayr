import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/storage/secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureStorageService storage;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    storage = SecureStorageService(storage: mockStorage);
  });

  group('SecureStorageService', () {
    test('setAuthToken writes token to storage', () async {
      when(() => mockStorage.write(
            key: 'auth_token',
            value: 'test-token',
          )).thenAnswer((_) async {});

      await storage.setAuthToken('test-token');

      verify(() => mockStorage.write(
            key: 'auth_token',
            value: 'test-token',
          )).called(1);
    });

    test('getAuthToken reads token from storage', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'stored-token');

      final token = await storage.getAuthToken();

      expect(token, 'stored-token');
      verify(() => mockStorage.read(key: 'auth_token')).called(1);
    });

    test('getAuthToken returns null when no token stored', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);

      final token = await storage.getAuthToken();

      expect(token, isNull);
    });

    test('setRefreshToken writes token to storage', () async {
      when(() => mockStorage.write(
            key: 'refresh_token',
            value: 'refresh-123',
          )).thenAnswer((_) async {});

      await storage.setRefreshToken('refresh-123');

      verify(() => mockStorage.write(
            key: 'refresh_token',
            value: 'refresh-123',
          )).called(1);
    });

    test('getRefreshToken reads token from storage', () async {
      when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'refreshed-token');

      final token = await storage.getRefreshToken();

      expect(token, 'refreshed-token');
    });

    test('setUserId writes userId to storage', () async {
      when(() => mockStorage.write(
            key: 'user_id',
            value: 'user-123',
          )).thenAnswer((_) async {});

      await storage.setUserId('user-123');

      verify(() => mockStorage.write(
            key: 'user_id',
            value: 'user-123',
          )).called(1);
    });

    test('getUserId reads userId from storage', () async {
      when(() => mockStorage.read(key: 'user_id'))
          .thenAnswer((_) async => 'user-456');

      final userId = await storage.getUserId();

      expect(userId, 'user-456');
    });

    test('clear deletes all stored tokens', () async {
      when(() => mockStorage.delete(key: 'auth_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'refresh_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'user_id')).thenAnswer((_) async {});

      await storage.clear();

      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
      verify(() => mockStorage.delete(key: 'user_id')).called(1);
    });
  });
}
