import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:talker_flutter/talker_flutter.dart';

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

class MockUser extends Mock implements supabase.User {}

void main() {
  late ChatRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockUser mockUser;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user-123');
    when(() => mockRemote.currentUser).thenReturn(mockUser);

    repository = ChatRepositoryImpl(
      remoteDatasource: mockRemote,
      talker: Talker(),
    );
  });

  group('ChatRepositoryImpl', () {
    group('getMyConversations', () {
      test('returns List<Conversation> on success', () async {
        final mockConversationsJson = [
          {
            'id': 'conv-1',
            'route_id': 'route-1',
            'student_id': 'user-123',
            'driver_user_id': 'driver-456',
            'last_message_at': '2026-06-04T12:00:00Z',
            'last_message_preview': 'Hello!',
            'created_at': '2026-06-04T10:00:00Z',
            'updated_at': '2026-06-04T12:00:00Z',
            'routes': {'title': 'Baghdad Route'},
            'student': {'full_name': 'Student Name'},
            'driver': {'full_name': 'Driver Name'},
          }
        ];

        when(() => mockRemote.getMyConversations('user-123'))
            .thenAnswer((_) async => mockConversationsJson);

        final result = await repository.getMyConversations();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (conversations) {
            expect(conversations.length, 1);
            expect(conversations.first.id, const ConversationId('conv-1'));
            expect(conversations.first.routeName, 'Baghdad Route');
            expect(conversations.first.otherUserName, 'Driver Name');
          },
        );
      });

      test('returns UnauthorizedFailure when user is not logged in', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.getMyConversations();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when datasource throws exception', () async {
        when(() => mockRemote.getMyConversations('user-123'))
            .thenThrow(Exception('DB Error'));

        final result = await repository.getMyConversations();

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect((failure as ServerFailure).message, contains('DB Error'));
          },
          (_) => fail('should fail'),
        );
      });
    });

    group('watchMyConversations', () {
      test('returns mapped Stream of Conversation list', () async {
        final controller = StreamController<List<Map<String, dynamic>>>();
        when(() => mockRemote.watchMyConversations('user-123'))
            .thenAnswer((_) => controller.stream);

        final stream = repository.watchMyConversations();

        expect(
          stream,
          emitsInOrder([
            [
              isA<Conversation>()
                  .having((c) => c.id, 'id', const ConversationId('conv-1'))
                  .having(
                    (c) => c.otherUserName,
                    'otherUserName',
                    'Driver Name',
                  ),
            ]
          ]),
        );

        controller.add([
          {
            'id': 'conv-1',
            'route_id': 'route-1',
            'student_id': 'user-123',
            'driver_user_id': 'driver-456',
            'last_message_at': '2026-06-04T12:00:00Z',
            'last_message_preview': 'Hello!',
            'created_at': '2026-06-04T10:00:00Z',
            'updated_at': '2026-06-04T12:00:00Z',
            'routes': {'title': 'Baghdad Route'},
            'student': {'full_name': 'Student Name'},
            'driver': {'full_name': 'Driver Name'},
          }
        ]);

        await controller.close();
      });

      test('emits UnauthorizedFailure when user is not logged in', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final stream = repository.watchMyConversations();

        await expectLater(
          stream,
          emitsError(isA<UnauthorizedFailure>()),
        );
      });
    });

    group('getOrCreateConversation', () {
      test('returns existing conversation if found', () async {
        final mockExistingJson = {
          'id': 'conv-1',
          'route_id': 'route-1',
          'student_id': 'user-123',
          'driver_user_id': 'driver-456',
          'last_message_at': '2026-06-04T12:00:00Z',
          'last_message_preview': 'Hello!',
          'created_at': '2026-06-04T10:00:00Z',
          'updated_at': '2026-06-04T12:00:00Z',
          'routes': {'title': 'Baghdad Route'},
          'student': {'full_name': 'Student Name'},
          'driver': {'full_name': 'Driver Name'},
        };

        when(
          () => mockRemote.getConversation(
            routeId: 'route-1',
            studentId: 'user-123',
          ),
        ).thenAnswer((_) async => mockExistingJson);

        final result = await repository.getOrCreateConversation(
          routeId: const RouteId('route-1'),
          driverUserId: const UserId('driver-456'),
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (conv) {
            expect(conv.id, const ConversationId('conv-1'));
            expect(conv.otherUserName, 'Driver Name');
          },
        );
        verifyNever(
          () => mockRemote.createConversation(
            routeId: any(named: 'routeId'),
            studentId: any(named: 'studentId'),
            driverUserId: any(named: 'driverUserId'),
          ),
        );
      });

      test('creates a new conversation if not found', () async {
        when(
          () => mockRemote.getConversation(
            routeId: 'route-1',
            studentId: 'user-123',
          ),
        ).thenAnswer((_) async => null);

        final mockCreatedJson = {
          'id': 'conv-2',
          'route_id': 'route-1',
          'student_id': 'user-123',
          'driver_user_id': 'driver-456',
          'created_at': '2026-06-04T12:00:00Z',
          'updated_at': '2026-06-04T12:00:00Z',
        };

        when(
          () => mockRemote.createConversation(
            routeId: 'route-1',
            studentId: 'user-123',
            driverUserId: 'driver-456',
          ),
        ).thenAnswer((_) async => mockCreatedJson);

        final result = await repository.getOrCreateConversation(
          routeId: const RouteId('route-1'),
          driverUserId: const UserId('driver-456'),
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (conv) {
            expect(conv.id, const ConversationId('conv-2'));
            expect(conv.otherUserName, isNull);
          },
        );
      });

      test('returns UnauthorizedFailure when not logged in', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.getOrCreateConversation(
          routeId: const RouteId('route-1'),
          driverUserId: const UserId('driver-456'),
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote getConversation throws exception',
          () async {
        when(
          () => mockRemote.getConversation(
            routeId: 'route-1',
            studentId: 'user-123',
          ),
        ).thenThrow(Exception('Server unreachable'));

        final result = await repository.getOrCreateConversation(
          routeId: const RouteId('route-1'),
          driverUserId: const UserId('driver-456'),
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              (failure as ServerFailure).message,
              contains('Server unreachable'),
            );
          },
          (_) => fail('should fail'),
        );
      });
    });

    group('getMessages', () {
      test('returns List<Message> on success', () async {
        final mockMessagesJson = [
          {
            'id': 'msg-1',
            'conversation_id': 'conv-1',
            'sender_id': 'user-123',
            'body': 'Test body',
            'created_at': '2026-06-04T12:00:00Z',
            'is_read': false,
          }
        ];

        when(() => mockRemote.getMessages('conv-1'))
            .thenAnswer((_) async => mockMessagesJson);

        final result =
            await repository.getMessages(const ConversationId('conv-1'));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (messages) {
            expect(messages.length, 1);
            expect(messages.first.id, const MessageId('msg-1'));
            expect(messages.first.body, 'Test body');
          },
        );
      });

      test('returns ServerFailure when remote getMessages throws exception',
          () async {
        when(() => mockRemote.getMessages('conv-1'))
            .thenThrow(Exception('Load messages failed'));

        final result =
            await repository.getMessages(const ConversationId('conv-1'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              (failure as ServerFailure).message,
              contains('Load messages failed'),
            );
          },
          (_) => fail('should fail'),
        );
      });
    });

    group('sendMessage', () {
      test('sends message and updates conversation preview', () async {
        final mockResponseJson = {
          'id': 'msg-2',
          'conversation_id': 'conv-1',
          'sender_id': 'user-123',
          'body': 'Hello world',
          'created_at': '2026-06-04T12:05:00Z',
          'is_read': false,
        };

        when(
          () => mockRemote.sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-123',
            body: 'Hello world',
          ),
        ).thenAnswer((_) async => mockResponseJson);

        when(
          () => mockRemote.updateConversationPreview(
            conversationId: 'conv-1',
            body: 'Hello world',
            updatedAt: any(named: 'updatedAt'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.sendMessage(
          conversationId: const ConversationId('conv-1'),
          body: 'Hello world',
        );

        expect(result.isRight(), true);
        verify(
          () => mockRemote.sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-123',
            body: 'Hello world',
          ),
        ).called(1);
        verify(
          () => mockRemote.updateConversationPreview(
            conversationId: 'conv-1',
            body: 'Hello world',
            updatedAt: any(named: 'updatedAt'),
          ),
        ).called(1);
      });

      test('returns UnauthorizedFailure when not logged in', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.sendMessage(
          conversationId: const ConversationId('conv-1'),
          body: 'Hello',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote sendMessage throws exception',
          () async {
        when(
          () => mockRemote.sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-123',
            body: 'Hello',
          ),
        ).thenThrow(Exception('Send failed'));

        final result = await repository.sendMessage(
          conversationId: const ConversationId('conv-1'),
          body: 'Hello',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect((failure as ServerFailure).message, contains('Send failed'));
          },
          (_) => fail('should fail'),
        );
      });
    });

    group('markAsRead', () {
      test('marks message as read successfully', () async {
        when(
          () => mockRemote.markMessageAsRead(
            messageId: 'msg-1',
            readAt: any(named: 'readAt'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.markAsRead(const MessageId('msg-1'));

        expect(result.isRight(), true);
        verify(
          () => mockRemote.markMessageAsRead(
            messageId: 'msg-1',
            readAt: any(named: 'readAt'),
          ),
        ).called(1);
      });

      test(
          'returns ServerFailure when remote markMessageAsRead throws exception',
          () async {
        when(
          () => mockRemote.markMessageAsRead(
            messageId: 'msg-1',
            readAt: any(named: 'readAt'),
          ),
        ).thenThrow(Exception('Database update failed'));

        final result = await repository.markAsRead(const MessageId('msg-1'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getUnreadCount', () {
      test('returns count on success', () async {
        when(() => mockRemote.getUnreadChatCount()).thenAnswer((_) async => 5);

        final result = await repository.getUnreadCount();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (count) => expect(count, 5),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getUnreadChatCount())
            .thenThrow(Exception('RPC error'));

        final result = await repository.getUnreadCount();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });
  });
}
