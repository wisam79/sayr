import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockOsrmRemoteDatasource extends Mock implements OsrmRemoteDatasource {}

void main() {
  late RoutingServiceImpl service;
  late MockOsrmRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockOsrmRemoteDatasource();
    service = RoutingServiceImpl(
      datasource: mockDatasource,
      talker: Talker(),
    );
  });

  group('RoutingServiceImpl', () {
    final start = Coordinates(latitude: 33.3152, longitude: 44.3661);
    final end = Coordinates(latitude: 33.3400, longitude: 44.4000);
    final geometry = [
      Coordinates(latitude: 33.3152, longitude: 44.3661),
      Coordinates(latitude: 33.3400, longitude: 44.4000),
    ];

    test('getRoute returns Right(List<Coordinates>) on success', () async {
      when(() => mockDatasource.getRouteGeometry(start, end))
          .thenAnswer((_) async => geometry);

      final result = await service.getRoute(start, end);

      expect(result.isRight(), true);
      expect(result.getRight().toNullable(), geometry);
    });

    test('getRoute returns Left(ServerFailure) on remote exception', () async {
      when(() => mockDatasource.getRouteGeometry(start, end))
          .thenThrow(Exception('HTTP 500'));

      final result = await service.getRoute(start, end);

      expect(result.isLeft(), true);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });
}
