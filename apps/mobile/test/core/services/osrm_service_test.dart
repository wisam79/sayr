import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_mobile/core/services/osrm_service.dart';

class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

void main() {
  group('OsrmService', () {
    late OsrmService osrmService;
    late MockDio mockDio;

    setUp(() {
      osrmService = OsrmService();
      mockDio = MockDio();
      osrmService.dioInstance = mockDio;
    });

    test('getRoute returns route coordinates on success', () async {
      const start = LatLng(33.5, 44.5);
      const end = LatLng(33.0, 44.0);

      final response = MockResponse();
      when(() => response.statusCode).thenReturn(200);
      when(() => response.data).thenReturn({
        'routes': [
          {
            'geometry': {
              'coordinates': [
                [44.5, 33.5],
                [44.0, 33.0],
              ],
            },
          }
        ],
      });

      when(() => mockDio.get<Map<String, dynamic>>(any())).thenAnswer((_) async => response);

      final route = await osrmService.getRoute(start, end);

      expect(route, isNotEmpty);
      expect(route.length, 2);
      expect(route.first.latitude, 33.5);
      expect(route.first.longitude, 44.5);
      expect(route.last.latitude, 33.0);
      expect(route.last.longitude, 44.0);
    });

    test('getRoute returns straight line fallback on API failure or timeout', () async {
      const start = LatLng(33.5, 44.5);
      const end = LatLng(33.0, 44.0);

      when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );

      final route = await osrmService.getRoute(start, end);

      expect(route, isNotEmpty);
      expect(route.length, 2);
      expect(route.first, start);
      expect(route.last, end);
    });
  });
}
