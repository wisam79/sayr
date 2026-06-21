import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/trip_remote_datasource.dart';
import 'package:sayr_data/src/models/rating_model.dart';
import 'package:sayr_data/src/models/trip_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../helpers/mock_supabase.dart';

class MockSupabaseStreamFilterBuilder extends Mock
    implements supabase.SupabaseStreamFilterBuilder {}

class MockSupabaseStreamBuilder extends Mock
    implements supabase.SupabaseStreamBuilder {}

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late TripRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();

    when(() => mockSupabase.client).thenReturn(mockClient);

    datasource = TripRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('TripRemoteDatasourceImpl', () {
    test('getActiveTrips returns trips list', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      final tripJson = {
        'id': 'trip1',
        'route_id': 'route1',
        'driver_id': 'driver1',
        'status': 'scheduled',
        'scheduled_at': '2026-06-21T00:00:00Z',
      };

      mockTransformBuilder.completeWith(Future.value([tripJson]));

      when(() => mockClient.from('trips')).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder1);
      when(
        () => mockFilterBuilder1.inFilter('status', [
          'scheduled',
          'driver_waiting',
          'in_transit',
        ]),
      ).thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.order('scheduled_at', ascending: true))
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getActiveTrips();

      expect(
          result,
          equals([
            TripModel.fromJson(tripJson),
          ]));
    });

    test('createTrip returns tripId', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<String>();
      mockRpcFilterBuilder.completeWith(Future.value('trip123'));

      final date = DateTime(2026, 6, 20);

      when(
        () => mockClient.rpc<String>(
          'create_trip',
          params: {
            'p_route_id': 'route1',
            'p_scheduled_at': date.toUtc().toIso8601String(),
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      final result =
          await datasource.createTrip(routeId: 'route1', scheduledAt: date);

      expect(result, equals('trip123'));
    });

    test('watchTrip streams data', () {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockStreamFilterBuilder = MockSupabaseStreamFilterBuilder();
      final mockStreamBuilder = MockSupabaseStreamBuilder();

      when(() => mockClient.from('trips')).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.stream(primaryKey: ['id']))
          .thenAnswer((_) => mockStreamFilterBuilder);
      when(() => mockStreamFilterBuilder.eq('id', 'trip1'))
          .thenAnswer((_) => mockStreamBuilder);

      final tripJson = {
        'id': 'trip1',
        'route_id': 'route1',
        'driver_id': 'driver1',
        'status': 'scheduled',
        'scheduled_at': '2026-06-21T00:00:00Z',
      };
      final expectedTrip = TripModel.fromJson(tripJson);

      when(() => mockStreamBuilder.map<List<TripModel>>(any()))
          .thenAnswer(
        (invocation) {
          final callback = invocation.positionalArguments[0] as List<TripModel> Function(List<Map<String, dynamic>>);
          return Stream.value(callback([tripJson]));
        },
      );

      final result = datasource.watchTrip('trip1');

      expect(
          result,
          emits([
            expectedTrip,
          ]));
    });

    test('getTripById returns trip', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      final tripJson = {
        'id': 'trip1',
        'route_id': 'route1',
        'driver_id': 'driver1',
        'status': 'scheduled',
        'scheduled_at': '2026-06-21T00:00:00Z',
      };
      mockTransformBuilder.completeWith(Future.value(tripJson));

      when(() => mockClient.from('trips')).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'trip1'))
          .thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle)
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getTripById('trip1');

      expect(result, equals(TripModel.fromJson(tripJson)));
    });

    test('updateTripStatus calls rpc', () async {
      final mockRpcFilterBuilder =
          MockPostgrestFilterBuilder<Map<String, dynamic>>();
      final tripJson = {
        'id': 'trip1',
        'route_id': 'route1',
        'driver_id': 'driver1',
        'status': 'in_transit',
        'scheduled_at': '2026-06-21T00:00:00Z',
      };
      mockRpcFilterBuilder.completeWith(Future.value(tripJson));

      when(
        () => mockClient.rpc<Map<String, dynamic>>(
          'update_trip_status',
          params: {
            'p_trip_id': 'trip1',
            'p_new_status': 'in_transit',
            'p_lat': null,
            'p_lng': null,
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.updateTripStatus(
          tripId: 'trip1', newStatus: 'in_transit');

      expect(result, equals(TripModel.fromJson(tripJson)));
    });

    test('updateTripBleOtp calls rpc', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<void>();
      mockRpcFilterBuilder.completeWith(Future.value(null));

      when(
        () => mockClient.rpc<void>(
          'update_trip_ble_otp',
          params: {
            'p_trip_id': 'trip1',
            'p_otp': '123456',
            'p_expires_at': '2026-06-20T12:00:00Z',
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      await datasource.updateTripBleOtp(
          tripId: 'trip1', otp: '123456', expiresAt: '2026-06-20T12:00:00Z');

      verify(
        () => mockClient.rpc<void>(
          'update_trip_ble_otp',
          params: {
            'p_trip_id': 'trip1',
            'p_otp': '123456',
            'p_expires_at': '2026-06-20T12:00:00Z',
          },
        ),
      ).called(1);
    });

    test('submitRating inserts and returns row', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>>();

      const expectedRating = RatingModel(
        id: 'rating1',
        tripId: 'trip1',
        studentId: 'student1',
        driverId: 'driver1',
        rating: 5,
        createdAt: '2026-06-21T00:00:00Z',
        comment: 'Good',
      );

      mockTransformBuilder.completeWith(Future.value({
        'id': 'rating1',
        'trip_id': 'trip1',
        'student_id': 'student1',
        'driver_id': 'driver1',
        'rating': 5,
        'created_at': '2026-06-21T00:00:00Z',
        'comment': 'Good',
      }));

      when(() => mockClient.from('ratings'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.insert({
          'trip_id': 'trip1',
          'driver_id': 'driver1',
          'student_id': 'student1',
          'rating': 5,
          'comment': 'Good',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.single).thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.submitRating(
        tripId: 'trip1',
        driverId: 'driver1',
        studentId: 'student1',
        rating: 5,
        comment: 'Good',
      );

      expect(result, equals(expectedRating));
    });
  });
}
