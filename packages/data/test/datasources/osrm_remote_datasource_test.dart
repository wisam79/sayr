import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/osrm_remote_datasource.dart';

import '../helpers/mock_supabase.dart';

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late OsrmRemoteDatasource datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();

    when(() => mockSupabase.client).thenReturn(mockClient);
    when(() => mockClient.functions).thenReturn(mockFunctions);

    datasource = OsrmRemoteDatasource(supabase: mockSupabase);
  });

  group('OsrmRemoteDatasource', () {
    const start = Coordinates(latitude: 33.3152, longitude: 44.3661);
    const end = Coordinates(latitude: 33.3400, longitude: 44.4000);

    test('getRouteGeometry returns list of Coordinates on success', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.status).thenReturn(200);
      when(() => mockResponse.data).thenReturn({
        'coordinates': [
          [44.3661, 33.3152],
          [44.4000, 33.3400],
        ]
      });

      when(
        () => mockFunctions.invoke(
          'get-route-geometry',
          body: {
            'startLng': start.longitude,
            'startLat': start.latitude,
            'endLng': end.longitude,
            'endLat': end.latitude,
          },
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await datasource.getRouteGeometry(start, end);

      expect(result.length, 2);
      expect(result[0].latitude, 33.3152);
      expect(result[0].longitude, 44.3661);
      expect(result[1].latitude, 33.3400);
      expect(result[1].longitude, 44.4000);
    });

    test('getRouteGeometry throws exception when status is not 200', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.status).thenReturn(500);

      when(
        () => mockFunctions.invoke(
          any(),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => mockResponse);

      expect(
        () => datasource.getRouteGeometry(start, end),
        throwsException,
      );
    });

    test('getRouteGeometry throws exception on null data', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.status).thenReturn(200);
      when(() => mockResponse.data).thenReturn(null);

      when(
        () => mockFunctions.invoke(
          any(),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => mockResponse);

      expect(
        () => datasource.getRouteGeometry(start, end),
        throwsException,
      );
    });
  });
}
