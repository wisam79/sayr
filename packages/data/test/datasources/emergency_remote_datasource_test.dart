import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/emergency_remote_datasource.dart';
import '../helpers/mock_supabase.dart';

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctionsClient;
  late EmergencyRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();
    mockFunctionsClient = MockFunctionsClient();

    when(() => mockSupabase.client).thenReturn(mockClient);
    when(() => mockClient.functions).thenReturn(mockFunctionsClient);

    datasource = EmergencyRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('EmergencyRemoteDatasourceImpl', () {
    test('triggerEmergency throws StateError if reportId is null', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.data).thenReturn(<String, dynamic>{});

      when(
        () => mockFunctionsClient.invoke(
          'emergency-alert',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => mockResponse);

      expect(
        () => datasource.triggerEmergency(
          tripId: 'trip1',
          routeId: 'route1',
          studentId: 'user1',
          lat: 1,
          lng: 2,
          description: 'Emergency',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('triggerEmergency returns reportId on success', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.data).thenReturn({'reportId': 'report123'});

      when(
        () => mockFunctionsClient.invoke(
          'emergency-alert',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await datasource.triggerEmergency(
        tripId: 'trip1',
        routeId: 'route1',
        studentId: 'user1',
        lat: 1,
        lng: 2,
        description: 'Emergency',
      );

      expect(result, equals('report123'));
      verify(
        () => mockFunctionsClient.invoke(
          'emergency-alert',
          body: {
            'studentId': 'user1',
            'routeId': 'route1',
            'tripId': 'trip1',
            'lat': 1.0,
            'lng': 2.0,
            'description': 'Emergency',
          },
        ),
      ).called(1);
    });

    test('getActiveEmergencyReport executes correct supabase query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder3 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder1 =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder2 =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilderSingle =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      mockTransformBuilderSingle.completeWith(Future.value({'id': 'report1'}));

      when(() => mockClient.from('emergency_reports'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('user_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.neq('status', 'resolved'))
          .thenAnswer((_) => mockFilterBuilder3);
      when(() => mockFilterBuilder3.order('created_at', ascending: false))
          .thenAnswer((_) => mockTransformBuilder1);
      when(() => mockTransformBuilder1.limit(1))
          .thenAnswer((_) => mockTransformBuilder2);
      when(mockTransformBuilder2.maybeSingle)
          .thenAnswer((_) => mockTransformBuilderSingle);

      final result = await datasource.getActiveEmergencyReport('user1');

      expect(result, equals({'id': 'report1'}));
    });

    test('resolveEmergencyReport executes correct supabase query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.completeWith(Future.value([]));

      when(() => mockClient.from('emergency_reports'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.update({
          'status': 'resolved',
          'resolved_at': '2026-06-20T12:00:00Z',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'report1'))
          .thenAnswer((_) => mockFilterBuilder);

      await datasource.resolveEmergencyReport(
          id: 'report1', resolvedAt: '2026-06-20T12:00:00Z');

      verify(() => mockFilterBuilder.eq('id', 'report1')).called(1);
    });
  });
}
