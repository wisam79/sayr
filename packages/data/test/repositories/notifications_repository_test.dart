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
  late NotificationsRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;
  late MockUser mockUser;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user-123');
    when(() => mockRemote.currentUser).thenReturn(mockUser);

    repository = NotificationsRepositoryImpl(
      remoteDatasource: mockRemote,
      talker: Talker(),
    );
  });

  group('NotificationsRepositoryImpl', () {
    group('getMyNotifications', () {
      test('returns List<AppNotification> on success', () async {
        final mockJson = [
          {
            'id': 'notif-1',
            'user_id': 'user-123',
            'title': 'Test Title',
            'body': 'Test Body',
            'is_read': false,
            'created_at': '2026-06-04T12:00:00Z',
          }
        ];

        when(() => mockRemote.getMyNotifications(userId: 'user-123', limit: 20))
            .thenAnswer((_) async => mockJson);

        final result = await repository.getMyNotifications(limit: 20);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (notifs) {
            expect(notifs.length, 1);
            expect(notifs.first.id, const NotificationId('notif-1'));
            expect(notifs.first.title, 'Test Title');
          },
        );
      });

      test('returns UnauthorizedFailure when user is null', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.getMyNotifications();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(
          () => mockRemote.getMyNotifications(
            userId: 'user-123',
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('Fetch failed'));

        final result = await repository.getMyNotifications();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getUnreadCount', () {
      test('returns count on success', () async {
        when(() => mockRemote.getUnreadNotificationCount('user-123'))
            .thenAnswer((_) async => 3);

        final result = await repository.getUnreadCount();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (count) => expect(count, 3),
        );
      });

      test('returns UnauthorizedFailure when user is null', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.getUnreadCount();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getUnreadNotificationCount('user-123'))
            .thenThrow(Exception('Count failed'));

        final result = await repository.getUnreadCount();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('markAsRead', () {
      test('calls markNotificationAsRead on remote datasource', () async {
        when(
          () => mockRemote.markNotificationAsRead(
            id: 'notif-1',
            readAt: any(named: 'readAt'),
          ),
        ).thenAnswer((_) async {});

        final result =
            await repository.markAsRead(const NotificationId('notif-1'));

        expect(result.isRight(), true);
        verify(
          () => mockRemote.markNotificationAsRead(
            id: 'notif-1',
            readAt: any(named: 'readAt'),
          ),
        ).called(1);
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(
          () => mockRemote.markNotificationAsRead(
            id: 'notif-1',
            readAt: any(named: 'readAt'),
          ),
        ).thenThrow(Exception('Mark read failed'));

        final result =
            await repository.markAsRead(const NotificationId('notif-1'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('markAllAsRead', () {
      test('calls markAllNotificationsAsRead on remote datasource', () async {
        when(
          () => mockRemote.markAllNotificationsAsRead(
            userId: 'user-123',
            readAt: any(named: 'readAt'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.markAllAsRead();

        expect(result.isRight(), true);
        verify(
          () => mockRemote.markAllNotificationsAsRead(
            userId: 'user-123',
            readAt: any(named: 'readAt'),
          ),
        ).called(1);
      });

      test('returns UnauthorizedFailure when user is null', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final result = await repository.markAllAsRead();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(
          () => mockRemote.markAllNotificationsAsRead(
            userId: 'user-123',
            readAt: any(named: 'readAt'),
          ),
        ).thenThrow(Exception('DB error'));

        final result = await repository.markAllAsRead();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('watchMyNotifications', () {
      test('returns stream of notifications', () async {
        final controller = StreamController<List<Map<String, dynamic>>>();
        when(() => mockRemote.watchMyNotifications('user-123'))
            .thenAnswer((_) => controller.stream);

        final stream = repository.watchMyNotifications();

        expect(
          stream,
          emitsInOrder([
            [
              isA<AppNotification>()
                  .having((n) => n.id, 'id', const NotificationId('notif-1')),
            ]
          ]),
        );

        controller.add([
          {
            'id': 'notif-1',
            'user_id': 'user-123',
            'title': 'Realtime Title',
            'body': 'Realtime Body',
            'is_read': false,
            'created_at': '2026-06-04T12:00:00Z',
          }
        ]);

        await controller.close();
      });

      test('emits UnauthorizedFailure when user is null', () async {
        when(() => mockRemote.currentUser).thenReturn(null);

        final stream = repository.watchMyNotifications();

        expect(stream, emitsError(isA<UnauthorizedFailure>()));
      });
    });

    group('registerPushToken', () {
      test('calls registerPushToken on remote datasource', () async {
        when(
          () => mockRemote.registerPushToken(
            fcmToken: 'token123',
            platform: 'android',
            deviceId: 'device123',
          ),
        ).thenAnswer((_) async {});

        final result = await repository.registerPushToken(
          fcmToken: 'token123',
          platform: 'android',
          deviceId: 'device123',
        );

        expect(result.isRight(), true);
        verify(
          () => mockRemote.registerPushToken(
            fcmToken: 'token123',
            platform: 'android',
            deviceId: 'device123',
          ),
        ).called(1);
      });

      test(
          'returns ServerFailure when remote registerPushToken throws exception',
          () async {
        when(
          () => mockRemote.registerPushToken(
            fcmToken: 'token123',
            platform: 'android',
            deviceId: any(named: 'deviceId'),
          ),
        ).thenThrow(Exception('Token registry failed'));

        final result = await repository.registerPushToken(
          fcmToken: 'token123',
          platform: 'android',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });
  });
}
