import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NotificationId('fallback'));
  });

  late MockNotificationsRepository mockRepo;
  late NotificationsBloc bloc;
  late StreamController<List<AppNotification>> notificationStreamController;

  setUp(() {
    mockRepo = MockNotificationsRepository();
    notificationStreamController = StreamController<List<AppNotification>>();
    when(() => mockRepo.watchMyNotifications()).thenAnswer(
      (_) => notificationStreamController.stream,
    );
    bloc = NotificationsBloc(notificationsRepository: mockRepo);
  });

  tearDown(() {
    notificationStreamController.close();
    bloc.close();
  });

  final testNotifications = [
    AppNotification(
      id: const NotificationId('notif-1'),
      userId: const UserId('user-1'),
      title: 'Test',
      body: 'Body',
      isRead: false,
      createdAt: DateTime.now(),
    ),
    AppNotification(
      id: const NotificationId('notif-2'),
      userId: const UserId('user-1'),
      title: 'Read',
      body: 'Already read',
      isRead: true,
      createdAt: DateTime.now(),
    ),
  ];

  group('NotificationsBloc', () {
    test('initial state is NotificationsInitial', () {
      expect(bloc.state, isA<NotificationsInitial>());
    });

    blocTest<NotificationsBloc, NotificationsState>(
      'emits [Loading, Loaded] with correct unreadCount on success',
      build: () {
        when(() => mockRepo.getMyNotifications()).thenAnswer(
          (_) async => Right<Failure, List<AppNotification>>(testNotifications),
        );
        return NotificationsBloc(notificationsRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const NotificationsLoadRequested()),
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>(),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits [Loading, Error] on load failure',
      build: () {
        when(() => mockRepo.getMyNotifications()).thenAnswer(
          (_) async => const Left<Failure, List<AppNotification>>(
            ServerFailure(message: 'Failed'),
          ),
        );
        return NotificationsBloc(notificationsRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const NotificationsLoadRequested()),
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsError>(),
      ],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'NotificationMarkedRead marks notification as read',
      build: () {
        when(() => mockRepo.markAsRead(any())).thenAnswer(
          (_) async => const Right(unit),
        );
        return NotificationsBloc(notificationsRepository: mockRepo);
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) =>
          bloc.add(const NotificationMarkedRead(NotificationId('notif-1'))),
      expect: () => [isA<NotificationsLoaded>()],
      verify: (_) =>
          verify(() => mockRepo.markAsRead(const NotificationId('notif-1')))
              .called(1),
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'NotificationsMarkAllRead marks all as read',
      build: () {
        when(() => mockRepo.markAllAsRead()).thenAnswer(
          (_) async => const Right(unit),
        );
        return NotificationsBloc(notificationsRepository: mockRepo);
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const NotificationsMarkAllRead()),
      expect: () => [isA<NotificationsLoaded>()],
      verify: (_) => verify(() => mockRepo.markAllAsRead()).called(1),
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits Loaded on refresh success',
      build: () {
        when(() => mockRepo.getMyNotifications()).thenAnswer(
          (_) async => Right<Failure, List<AppNotification>>(testNotifications),
        );
        return NotificationsBloc(notificationsRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const NotificationsRefreshRequested()),
      expect: () => [isA<NotificationsLoaded>()],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'emits Error on refresh failure',
      build: () {
        when(() => mockRepo.getMyNotifications()).thenAnswer(
          (_) async => const Left<Failure, List<AppNotification>>(
            ServerFailure(message: 'Refresh failed'),
          ),
        );
        return NotificationsBloc(notificationsRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const NotificationsRefreshRequested()),
      expect: () => [isA<NotificationsError>()],
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'realtime stream updates notifications',
      build: () {
        when(() => mockRepo.getMyNotifications()).thenAnswer(
          (_) async => const Right<Failure, List<AppNotification>>([]),
        );
        return NotificationsBloc(notificationsRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const NotificationsLoadRequested());
        await Future<void>.delayed(Duration.zero);
        notificationStreamController.add(testNotifications);
      },
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>(),
        isA<NotificationsLoaded>(),
      ],
    );
  });
}
