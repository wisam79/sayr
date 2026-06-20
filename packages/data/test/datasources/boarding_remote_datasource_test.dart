import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/boarding_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../helpers/mock_supabase.dart';

class MockSupabaseStreamFilterBuilder extends Mock
    implements supabase.SupabaseStreamFilterBuilder {}

class MockSupabaseStreamBuilder extends Mock
    implements supabase.SupabaseStreamBuilder {}

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late BoardingRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();

    when(() => mockSupabase.client).thenReturn(mockClient);

    datasource = BoardingRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('BoardingRemoteDatasourceImpl', () {
    test(
        'getActiveTripForSubscription throws AuthException if not authenticated',
        () async {
      when(() => mockSupabase.currentUser).thenReturn(null);

      expect(
        () => datasource.getActiveTripForSubscription(),
        throwsA(isA<supabase.AuthException>()),
      );
    });

    test('getActiveTripForSubscription returns null if no active subscription',
        () async {
      final user = MockUser();
      when(() => user.id).thenReturn('user1');
      when(() => mockSupabase.currentUser).thenReturn(user);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder1 =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilderSingle =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();
      mockTransformBuilderSingle.completeWith(Future.value());

      when(() => mockClient.from('subscriptions'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select('route_id'))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('student_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('status', 'active'))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.order('start_date', ascending: false))
          .thenAnswer((_) => mockTransformBuilder1);
      when(() => mockTransformBuilder1.limit(1))
          .thenAnswer((_) => mockTransformBuilder1);
      when(mockTransformBuilder1.maybeSingle)
          .thenAnswer((_) => mockTransformBuilderSingle);

      final result = await datasource.getActiveTripForSubscription();

      expect(result, isNull);
    });

    test(
        'getActiveTripForSubscription calls get_active_trip_for_route if subscription exists',
        () async {
      final user = MockUser();
      when(() => user.id).thenReturn('user1');
      when(() => mockSupabase.currentUser).thenReturn(user);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder1 =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilderSingle =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();
      mockTransformBuilderSingle
          .completeWith(Future.value({'route_id': 'route1'}));

      when(() => mockClient.from('subscriptions'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select('route_id'))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('student_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('status', 'active'))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.order('start_date', ascending: false))
          .thenAnswer((_) => mockTransformBuilder1);
      when(() => mockTransformBuilder1.limit(1))
          .thenAnswer((_) => mockTransformBuilder1);
      when(mockTransformBuilder1.maybeSingle)
          .thenAnswer((_) => mockTransformBuilderSingle);

      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<String?>();
      mockRpcFilterBuilder.completeWith(Future.value('trip1'));
      when(() => mockClient.rpc<String?>('get_active_trip_for_route',
              params: {'p_route_id': 'route1'}))
          .thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.getActiveTripForSubscription();

      expect(result, equals('trip1'));
    });

    test('generateBoardingToken throws PostgrestException if response is empty',
        () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(Future.value([]));
      when(() => mockClient.rpc<List<dynamic>>('generate_boarding_token',
              params: {'p_trip_id': 'trip1'}))
          .thenAnswer((_) => mockRpcFilterBuilder);

      expect(
        () => datasource.generateBoardingToken('trip1'),
        throwsA(isA<supabase.PostgrestException>()),
      );
    });

    test('generateBoardingToken returns token and expiresAt on success',
        () async {
      final expires = DateTime.now().toIso8601String();
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(
        Future.value([
          {'token': 'token123', 'expires_at': expires},
        ]),
      );
      when(() => mockClient.rpc<List<dynamic>>('generate_boarding_token',
              params: {'p_trip_id': 'trip1'}))
          .thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.generateBoardingToken('trip1');

      expect(result.token, equals('token123'));
      expect(result.expiresAt, equals(DateTime.parse(expires)));
    });

    test('validateBoarding throws PostgrestException if response is empty',
        () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(Future.value([]));
      when(
        () => mockClient.rpc<List<dynamic>>(
          'validate_boarding',
          params: {
            'p_token': 'token1',
            'p_trip_id': 'trip1',
            'p_lat': null,
            'p_lng': null,
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      expect(
        () => datasource.validateBoarding(token: 'token1', tripId: 'trip1'),
        throwsA(isA<supabase.PostgrestException>()),
      );
    });

    test('validateBoarding returns result on success', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(
        Future.value([
          {'status': 'success'},
        ]),
      );
      when(
        () => mockClient.rpc<List<dynamic>>(
          'validate_boarding',
          params: {
            'p_token': 'token1',
            'p_trip_id': 'trip1',
            'p_lat': 1.0,
            'p_lng': 2.0,
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.validateBoarding(
          token: 'token1', tripId: 'trip1', lat: 1, lng: 2);

      expect(result, equals({'status': 'success'}));
    });

    test('getTripPassengers returns mapped list', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(
        Future.value([
          {'user_id': '1'},
          {'user_id': '2'},
        ]),
      );
      when(() => mockClient.rpc<List<dynamic>>('get_trip_passengers',
              params: {'p_trip_id': 'trip1'}))
          .thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.getTripPassengers('trip1');

      expect(
        result,
        equals([
          {'user_id': '1'},
          {'user_id': '2'},
        ]),
      );
    });

    test('watchTripPassengers delegates to stream', () {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockStreamFilterBuilder = MockSupabaseStreamFilterBuilder();
      final mockStreamBuilder = MockSupabaseStreamBuilder();

      when(() => mockClient.from('boardings'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.stream(primaryKey: ['id']))
          .thenAnswer((_) => mockStreamFilterBuilder);
      when(() => mockStreamFilterBuilder.eq('trip_id', 'trip1'))
          .thenAnswer((_) => mockStreamFilterBuilder);
      when(() => mockStreamFilterBuilder.order('boarded_at'))
          .thenAnswer((_) => mockStreamBuilder);

      when(() => mockStreamBuilder.map<List<Map<String, dynamic>>>(any()))
          .thenAnswer(
        (_) => Stream.value([
          {'id': '1'},
        ]),
      );

      final result = datasource.watchTripPassengers('trip1');

      expect(
        result,
        emits([
          {'id': '1'},
        ]),
      );
    });

    test(
        'validateBoardingViaProximity throws PostgrestException if response is empty',
        () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(Future.value([]));
      when(
        () => mockClient.rpc<List<dynamic>>(
          'validate_boarding_via_proximity',
          params: {
            'p_trip_id': 'trip1',
            'p_otp': '123456',
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      expect(
        () => datasource.validateBoardingViaProximity(
            tripId: 'trip1', otp: '123456'),
        throwsA(isA<supabase.PostgrestException>()),
      );
    });

    test('validateBoardingViaProximity returns result on success', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(
        Future.value([
          {'status': 'success'},
        ]),
      );
      when(
        () => mockClient.rpc<List<dynamic>>(
          'validate_boarding_via_proximity',
          params: {
            'p_trip_id': 'trip1',
            'p_otp': '123456',
            'p_student_lat': 1.0,
            'p_student_lng': 2.0,
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.validateBoardingViaProximity(
          tripId: 'trip1', otp: '123456', lat: 1, lng: 2);

      expect(result, equals({'status': 'success'}));
    });
  });
}
