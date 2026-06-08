import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:sayr_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

void main() {
  late MockNotificationsBloc mockBloc;

  final testNotifications = [
    AppNotification(
      id: const NotificationId('notif-1'),
      userId: const UserId('user-1'),
      title: 'Trip Update',
      body: 'Your trip to Baghdad has been confirmed',
      isRead: false,
      createdAt: DateTime.parse('2026-06-07T08:00:00Z'),
      data: {'type': 'trip'},
    ),
    AppNotification(
      id: const NotificationId('notif-2'),
      userId: const UserId('user-1'),
      title: 'Payment Received',
      body: 'Your payment of 5000 IQD was successful',
      isRead: true,
      createdAt: DateTime.parse('2026-06-06T10:00:00Z'),
      data: {'type': 'payment'},
    ),
  ];

  setUp(() {
    mockBloc = MockNotificationsBloc();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: BlocProvider<NotificationsBloc>.value(
        value: mockBloc,
        child: child,
      ),
    );
  }

  testWidgets('shows loading indicator when state is NotificationsLoading',
      (tester) async {
    when(() => mockBloc.state).thenReturn(const NotificationsState.loading());

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no notifications', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const NotificationsState.loaded(notifications: []),
    );

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();

    expect(find.text('لا توجد إشعارات'), findsOneWidget);
  });

  testWidgets('shows notification list when loaded', (tester) async {
    when(() => mockBloc.state).thenReturn(
      NotificationsState.loaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
    );

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();

    expect(
      find.text('Trip Update'),
      findsOneWidget,
    );
    expect(
      find.text('Your trip to Baghdad has been confirmed'),
      findsOneWidget,
    );
    expect(
      find.text('Payment Received'),
      findsOneWidget,
    );
    expect(
      find.text('Your payment of 5000 IQD was successful'),
      findsOneWidget,
    );
  });

  testWidgets('shows mark all as read button when unread exists',
      (tester) async {
    when(() => mockBloc.state).thenReturn(
      NotificationsState.loaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
    );

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();

    expect(find.text('تحديد الكل كمقروء'), findsOneWidget);
  });

  testWidgets('shows error body with retry button', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const NotificationsState.error(
        failure: ServerFailure(message: 'Connection failed'),
      ),
    );

    await tester.pumpWidget(wrap(const NotificationsPage()));
    await tester.pump();

    expect(find.text('Connection failed'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
