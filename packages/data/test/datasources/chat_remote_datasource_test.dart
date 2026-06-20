import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/chat_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../helpers/mock_supabase.dart';

class MockSupabaseStreamFilterBuilder extends Mock
    implements supabase.SupabaseStreamFilterBuilder {}

class MockSupabaseStreamBuilder extends Mock
    implements supabase.SupabaseStreamBuilder {}

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late ChatRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();

    when(() => mockSupabase.client).thenReturn(mockClient);

    datasource = ChatRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('ChatRemoteDatasourceImpl', () {
    test('getMyConversations executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      mockTransformBuilder.completeWith(Future.value([
        {'id': 'conv1'}
      ]));

      when(() => mockClient.from('conversations'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any()))
          .thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1
              .or('student_id.eq.user1,driver_user_id.eq.user1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.order('updated_at', ascending: false))
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getMyConversations('user1');

      expect(
          result,
          equals([
            {'id': 'conv1'}
          ]));
    });

    test('watchMyConversations streams data', () {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockStreamFilterBuilder = MockSupabaseStreamFilterBuilder();
      final mockStreamBuilder = MockSupabaseStreamBuilder();

      when(() => mockClient.from('conversations'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.stream(primaryKey: ['id']))
          .thenAnswer((_) => mockStreamFilterBuilder);
      when(() => mockStreamFilterBuilder.order('updated_at'))
          .thenAnswer((_) => mockStreamBuilder);

      when(() => mockStreamBuilder.map<List<Map<String, dynamic>>>(any()))
          .thenAnswer(
        (_) => Stream.value([
          {'id': 'conv1'},
        ]),
      );

      final result = datasource.watchMyConversations('user1');

      expect(
          result,
          emits([
            {'id': 'conv1'}
          ]));
    });

    test('getConversation executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      mockTransformBuilder.completeWith(Future.value({'id': 'conv1'}));

      when(() => mockClient.from('conversations'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('route_id', 'route1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.eq('student_id', 'student1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(mockFilterBuilder2.maybeSingle)
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getConversation(
          routeId: 'route1', studentId: 'student1');

      expect(result, equals({'id': 'conv1'}));
    });

    test('createConversation inserts and returns single', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>>();

      mockTransformBuilder.completeWith(Future.value({'id': 'conv2'}));

      when(() => mockClient.from('conversations'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.insert({
          'route_id': 'route1',
          'student_id': 'student1',
          'driver_user_id': 'driver1',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.single).thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.createConversation(
          routeId: 'route1', studentId: 'student1', driverUserId: 'driver1');

      expect(result, equals({'id': 'conv2'}));
    });

    test('getMessages executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      mockTransformBuilder.completeWith(Future.value([
        {'id': 'msg1'}
      ]));

      when(() => mockClient.from('messages'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('conversation_id', 'conv1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.order('created_at', ascending: true))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.limit(50))
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getMessages('conv1');

      expect(
          result,
          equals([
            {'id': 'msg1'}
          ]));
    });

    test('watchMessages streams data', () {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockStreamFilterBuilder = MockSupabaseStreamFilterBuilder();
      final mockStreamBuilder = MockSupabaseStreamBuilder();

      when(() => mockClient.from('messages'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.stream(primaryKey: ['id']))
          .thenAnswer((_) => mockStreamFilterBuilder);
      when(() => mockStreamFilterBuilder.eq('conversation_id', 'conv1'))
          .thenAnswer((_) => mockStreamBuilder);

      when(() => mockStreamBuilder.map<List<Map<String, dynamic>>>(any()))
          .thenAnswer(
        (_) => Stream.value([
          {'id': 'msg1'},
        ]),
      );

      final result = datasource.watchMessages('conv1');

      expect(
          result,
          emits([
            {'id': 'msg1'}
          ]));
    });

    test('sendMessage inserts and returns single', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>>();

      mockTransformBuilder.completeWith(Future.value({'id': 'msg2'}));

      when(() => mockClient.from('messages'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.insert({
          'conversation_id': 'conv1',
          'sender_id': 'sender1',
          'body': 'Hello',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.single).thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.sendMessage(
          conversationId: 'conv1', senderId: 'sender1', body: 'Hello');

      expect(result, equals({'id': 'msg2'}));
    });

    test('markMessageAsRead executes update', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.completeWith(Future.value([]));

      when(() => mockClient.from('messages'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.update({
          'is_read': true,
          'read_at': '2026-06-20T12:00:00Z',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'msg1'))
          .thenAnswer((_) => mockFilterBuilder);

      await datasource.markMessageAsRead(
          messageId: 'msg1', readAt: '2026-06-20T12:00:00Z');

      verify(() => mockFilterBuilder.eq('id', 'msg1')).called(1);
    });

    test('getUnreadChatCount executes rpc', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<int>();
      mockRpcFilterBuilder.completeWith(Future.value(5));

      when(() => mockClient.rpc<int>('get_unread_count'))
          .thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.getUnreadChatCount();

      expect(result, equals(5));
    });

    test('updateConversationPreview executes update', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.completeWith(Future.value([]));

      when(() => mockClient.from('conversations'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.update({
          'last_message_at': '2026-06-20T12:00:00Z',
          'last_message_preview': 'Hello World',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'conv1'))
          .thenAnswer((_) => mockFilterBuilder);

      await datasource.updateConversationPreview(
          conversationId: 'conv1',
          body: 'Hello World',
          updatedAt: '2026-06-20T12:00:00Z');

      verify(() => mockFilterBuilder.eq('id', 'conv1')).called(1);
    });
  });
}
