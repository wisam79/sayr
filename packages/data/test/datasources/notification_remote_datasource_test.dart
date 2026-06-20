import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/notification_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../helpers/mock_supabase.dart';

class MockSupabaseStreamFilterBuilder extends Mock
    implements supabase.SupabaseStreamFilterBuilder {}

class MockSupabaseStreamBuilder extends Mock
    implements supabase.SupabaseStreamBuilder {}

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late NotificationRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();

    when(() => mockSupabase.client).thenReturn(mockClient);

    datasource = NotificationRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('NotificationRemoteDatasourceImpl', () {
    test('getMyNotifications executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder1 =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder2 =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      mockTransformBuilder2.completeWith(Future.value([
        {'id': 'notif1'}
      ]));

      when(() => mockClient.from('notification_log'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('user_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.order('created_at', ascending: false))
          .thenAnswer((_) => mockTransformBuilder1);
      when(() => mockTransformBuilder1.limit(50))
          .thenAnswer((_) => mockTransformBuilder2);

      final result = await datasource.getMyNotifications(userId: 'user1');

      expect(
          result,
          equals([
            {'id': 'notif1'}
          ]));
    });

    test('getUnreadNotificationCount executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder3 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

      mockFilterBuilder3.completeWith(
        Future.value([
          {'id': 'notif1'},
          {'id': 'notif2'},
        ]),
      );

      when(() => mockClient.from('notification_log'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select('id'))
          .thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('user_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.eq('is_read', false))
          .thenAnswer((_) => mockFilterBuilder3);

      final result = await datasource.getUnreadNotificationCount('user1');

      expect(result, equals(2));
    });

    test('markNotificationAsRead executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.completeWith(Future.value([]));

      when(() => mockClient.from('notification_log'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.update({
          'is_read': true,
          'read_at': '2026-06-20T12:00:00Z',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'notif1'))
          .thenAnswer((_) => mockFilterBuilder);

      await datasource.markNotificationAsRead(
          id: 'notif1', readAt: '2026-06-20T12:00:00Z');

      verify(() => mockFilterBuilder.eq('id', 'notif1')).called(1);
    });

    test('markAllNotificationsAsRead executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder2.completeWith(Future.value([]));

      when(() => mockClient.from('notification_log'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.update({
          'is_read': true,
          'read_at': '2026-06-20T12:00:00Z',
        }),
      ).thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('user_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.eq('is_read', false))
          .thenAnswer((_) => mockFilterBuilder2);

      await datasource.markAllNotificationsAsRead(
          userId: 'user1', readAt: '2026-06-20T12:00:00Z');

      verify(() => mockFilterBuilder2.eq('is_read', false)).called(1);
    });

    test('watchMyNotifications streams data', () {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockStreamFilterBuilder = MockSupabaseStreamFilterBuilder();
      final mockStreamBuilder = MockSupabaseStreamBuilder();

      when(() => mockClient.from('notification_log'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.stream(primaryKey: ['id']))
          .thenAnswer((_) => mockStreamFilterBuilder);
      when(() => mockStreamFilterBuilder.eq('user_id', 'user1'))
          .thenAnswer((_) => mockStreamBuilder);

      when(() => mockStreamBuilder.map<List<Map<String, dynamic>>>(any()))
          .thenAnswer(
        (_) => Stream.value([
          {'id': 'notif1'},
        ]),
      );

      final result = datasource.watchMyNotifications('user1');

      expect(
          result,
          emits([
            {'id': 'notif1'}
          ]));
    });

    test('registerPushToken executes rpc', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<void>();
      mockRpcFilterBuilder.completeWith(Future.value());

      when(
        () => mockClient.rpc<void>(
          'register_push_token',
          params: {
            'p_token': 'fcmToken',
            'p_platform': 'android',
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      await datasource.registerPushToken(
          fcmToken: 'fcmToken', platform: 'android');

      verify(
        () => mockClient.rpc<void>(
          'register_push_token',
          params: {
            'p_token': 'fcmToken',
            'p_platform': 'android',
          },
        ),
      ).called(1);
    });

    test('deactivatePushTokens executes rpc', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<void>();
      mockRpcFilterBuilder.completeWith(Future.value());

      when(() => mockClient.rpc<void>('deactivate_push_tokens'))
          .thenAnswer((_) => mockRpcFilterBuilder);

      await datasource.deactivatePushTokens();

      verify(() => mockClient.rpc<void>('deactivate_push_tokens')).called(1);
    });
  });
}
