import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'package:talker_flutter/talker_flutter.dart';

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

class MockLocalDatasource extends Mock implements LocalDatasource {}

void main() {
  late RouteRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockLocalDatasource mockLocal;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockLocal = MockLocalDatasource();
    repository = RouteRepositoryImpl(
      remoteDatasource: mockRemote,
      localDatasource: mockLocal,
      talker: Talker(),
    );
  });

  group('RouteRepositoryImpl', () {
    final mockRouteJson = {
      'id': 'route-123',
      'driver_id': 'driver-456',
      'title': 'Baghdad Route',
      'start_location': 'Start Point',
      'end_location': 'End Point',
      'price': 50000,
      'capacity': 30,
      'available_seats': 10,
      'is_active': true,
    };

    group('getActiveRoutes', () {
      test('returns List<Route> on success', () async {
        when(() => mockRemote.getActiveRoutes())
            .thenAnswer((_) async => [mockRouteJson]);

        final result = await repository.getActiveRoutes();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (routes) {
            expect(routes.length, 1);
            expect(routes.first.id, const RouteId('route-123'));
            expect(routes.first.title, 'Baghdad Route');
          },
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getActiveRoutes())
            .thenThrow(Exception('HTTP 500'));

        final result = await repository.getActiveRoutes();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getById', () {
      test('returns Route when found', () async {
        when(() => mockRemote.getRouteById('route-123'))
            .thenAnswer((_) async => mockRouteJson);

        final result = await repository.getById(const RouteId('route-123'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (route) {
            expect(route.id, const RouteId('route-123'));
            expect(route.title, 'Baghdad Route');
          },
        );
      });

      test('returns Left(NotFoundFailure) when not found', () async {
        when(() => mockRemote.getRouteById('route-123'))
            .thenAnswer((_) async => null);

        final result = await repository.getById(const RouteId('route-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getRouteById('route-123'))
            .thenThrow(Exception('DB Error'));

        final result = await repository.getById(const RouteId('route-123'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('search', () {
      test('returns List<Route> matching query', () async {
        when(() => mockRemote.searchRoutes('Baghdad'))
            .thenAnswer((_) async => [mockRouteJson]);

        final result = await repository.search('Baghdad');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (routes) {
            expect(routes.length, 1);
            expect(routes.first.title, 'Baghdad Route');
          },
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.searchRoutes('Baghdad'))
            .thenThrow(Exception('Search error'));

        final result = await repository.search('Baghdad');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });
  });
}
