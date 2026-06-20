import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/route_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../helpers/mock_supabase.dart';

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late RouteRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();

    when(() => mockSupabase.client).thenReturn(mockClient);
    when(() => mockSupabase.currentUser).thenReturn(null);

    datasource = RouteRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('RouteRemoteDatasourceImpl', () {
    test('getActiveRoutes executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      mockTransformBuilder.completeWith(Future.value([
        {'id': 'route1'}
      ]));

      when(() => mockClient.from('routes')).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('is_active', true))
          .thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.order('title'))
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getActiveRoutes();

      expect(
          result,
          equals([
            {'id': 'route1'}
          ]));
    });

    test('getMyDriverRoutes throws AuthException if user is null', () async {
      expect(
        () => datasource.getMyDriverRoutes(),
        throwsA(isA<supabase.AuthException>()),
      );
    });

    test('getMyDriverRoutes returns empty list if no driver record', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user1');
      when(() => mockSupabase.currentUser).thenReturn(mockUser);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder1 =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      mockTransformBuilder1.completeWith(Future.value());

      when(() => mockClient.from('drivers'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select('id'))
          .thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('user_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder1);
      when(mockFilterBuilder1.maybeSingle)
          .thenAnswer((_) => mockTransformBuilder1);

      final result = await datasource.getMyDriverRoutes();

      expect(result, isEmpty);
    });

    test('getMyDriverRoutes returns routes if driver exists', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user1');
      when(() => mockSupabase.currentUser).thenReturn(mockUser);

      final mockDriverQueryBuilder = MockSupabaseQueryBuilder();
      final mockDriverFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockDriverTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      mockDriverTransformBuilder.completeWith(Future.value({'id': 'driver1'}));

      when(() => mockClient.from('drivers'))
          .thenAnswer((_) => mockDriverQueryBuilder);
      when(() => mockDriverQueryBuilder.select('id'))
          .thenAnswer((_) => mockDriverFilterBuilder);
      when(() => mockDriverFilterBuilder.eq('user_id', 'user1'))
          .thenAnswer((_) => mockDriverFilterBuilder);
      when(mockDriverFilterBuilder.maybeSingle)
          .thenAnswer((_) => mockDriverTransformBuilder);

      final mockRouteQueryBuilder = MockSupabaseQueryBuilder();
      final mockRouteFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockRouteTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      mockRouteTransformBuilder.completeWith(Future.value([
        {'id': 'route1'}
      ]));

      when(() => mockClient.from('routes'))
          .thenAnswer((_) => mockRouteQueryBuilder);
      when(mockRouteQueryBuilder.select)
          .thenAnswer((_) => mockRouteFilterBuilder);
      when(() => mockRouteFilterBuilder.eq('driver_id', 'driver1'))
          .thenAnswer((_) => mockRouteFilterBuilder);
      when(() => mockRouteFilterBuilder.eq('is_active', true))
          .thenAnswer((_) => mockRouteFilterBuilder);
      when(() => mockRouteFilterBuilder.order('title'))
          .thenAnswer((_) => mockRouteTransformBuilder);

      final result = await datasource.getMyDriverRoutes();

      expect(
          result,
          equals([
            {'id': 'route1'}
          ]));
    });

    test('getRouteById returns route', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      mockTransformBuilder.completeWith(Future.value({'id': 'route1'}));

      when(() => mockClient.from('routes')).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'route1'))
          .thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle)
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getRouteById('route1');

      expect(result, equals({'id': 'route1'}));
    });

    test('searchRoutes executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      mockTransformBuilder.completeWith(Future.value([
        {'id': 'route1'}
      ]));

      when(() => mockClient.from('routes')).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('is_active', true))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.or(
              'title.ilike.%query%,start_location.ilike.%query%,end_location.ilike.%query%'))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.order('title'))
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.searchRoutes('query');

      expect(
          result,
          equals([
            {'id': 'route1'}
          ]));
    });
  });
}
