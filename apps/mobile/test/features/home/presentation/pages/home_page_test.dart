import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/pages/home_page.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/driver_home_tab.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/student_home_tab.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockSubscriptionsBloc extends MockBloc<SubscriptionsEvent, SubscriptionsState> implements SubscriptionsBloc {}
class MockNotificationsBloc extends MockBloc<NotificationsEvent, NotificationsState> implements NotificationsBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockSubscriptionsBloc mockSubscriptionsBloc;
  late MockNotificationsBloc mockNotificationsBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockSubscriptionsBloc = MockSubscriptionsBloc();
    mockNotificationsBloc = MockNotificationsBloc();

    when(() => mockSubscriptionsBloc.state).thenReturn(const SubscriptionsInitial());
    when(() => mockNotificationsBloc.state).thenReturn(const NotificationsState.initial());
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<SubscriptionsBloc>.value(value: mockSubscriptionsBloc),
          BlocProvider<NotificationsBloc>.value(value: mockNotificationsBloc),
        ],
        child: child,
      ),
    );
  }

  group('HomePage Widget Tests', () {
    testWidgets('renders StudentHomeTab for student user', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthAuthenticated(
          User(
            id: UserId('1'),
            email: 'student@test.com',
            role: UserRole.student,
            fullName: 'Student',
            phone: '123',
          ),
        ),
      );

      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(StudentHomeTab), findsOneWidget);
      expect(find.byType(DriverHomeTab), findsNothing);
    });

    testWidgets('renders DriverHomeTab for driver user', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthAuthenticated(
          User(
            id: UserId('2'),
            email: 'driver@test.com',
            role: UserRole.driver,
            fullName: 'Driver',
            phone: '123',
          ),
        ),
      );

      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(DriverHomeTab), findsOneWidget);
      expect(find.byType(StudentHomeTab), findsNothing);
    });
  });
}
