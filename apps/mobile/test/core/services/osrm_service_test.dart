import 'package:flutter_test/flutter_test.dart';
import 'package:functions_client/functions_client.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/core/services/osrm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sfs;

class MockSupabaseClient extends Mock implements sfs.SupabaseClient {}

class MockFunctionsClient extends Mock implements sfs.FunctionsClient {}

class MockSayrSupabase extends Mock implements SayrSupabase {}

void main() {
  group('OsrmService', () {
    late OsrmService osrmService;
    late MockSayrSupabase mockSupabase;
    late MockSupabaseClient mockClient;
    late MockFunctionsClient mockFunctions;

    setUp(() {
      mockSupabase = MockSayrSupabase();
      mockClient = MockSupabaseClient();
      mockFunctions = MockFunctionsClient();

      when(() => mockSupabase.client).thenReturn(mockClient);
      when(() => mockClient.functions).thenReturn(mockFunctions);

      osrmService = OsrmService(supabase: mockSupabase);
    });

    test('getRoute returns route coordinates on success', () async {
      const start = LatLng(33.5, 44.5);
      const end = LatLng(33, 44);

      final response = FunctionResponse(
        data: {
          'coordinates': [
            [44.5, 33.5],
            [44.0, 33.0],
          ],
        },
        status: 200,
      );

      when(
        () => mockFunctions.invoke(
          any(),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => response);

      final route = await osrmService.getRoute(start, end);

      expect(route, isNotEmpty);
      expect(route.length, 2);
      expect(route.first.latitude, 33.5);
      expect(route.first.longitude, 44.5);
      expect(route.last.latitude, 33.0);
      expect(route.last.longitude, 44.0);

      verify(
        () => mockFunctions.invoke(
          'get-route-geometry',
          body: {
            'startLng': 44.5,
            'startLat': 33.5,
            'endLng': 44.0,
            'endLat': 33.0,
          },
        ),
      ).called(1);
    });

    test('getRoute returns straight line fallback on failure', () async {
      const start = LatLng(33.5, 44.5);
      const end = LatLng(33, 44);

      when(
        () => mockFunctions.invoke(
          any(),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('network error'));

      final route = await osrmService.getRoute(start, end);

      expect(route, isNotEmpty);
      expect(route.length, 2);
      expect(route.first, start);
      expect(route.last, end);
    });
  });
}
