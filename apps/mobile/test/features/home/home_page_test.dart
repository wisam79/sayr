import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/locale_cubit.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/pages/home_page.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockSubscriptionsBloc
    extends MockBloc<SubscriptionsEvent, SubscriptionsState>
    implements SubscriptionsBloc {}

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

class MockTrackingBloc extends MockBloc<TrackingEvent, TrackingState>
    implements TrackingBloc {}

class MockRoutesBloc extends MockBloc<RoutesEvent, RoutesState>
    implements RoutesBloc {}

class MockLocaleCubit extends MockCubit<Locale> implements LocaleCubit {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockSubscriptionsBloc mockSubsBloc;
  late MockNotificationsBloc mockNotifsBloc;
  late MockTrackingBloc mockTrackingBloc;
  late MockRoutesBloc mockRoutesBloc;
  late MockLocaleCubit mockLocaleCubit;

  const testStudent = User(
    id: UserId('student-1'),
    email: 'student@sayr.app',
    fullName: 'Student User',
    role: UserRole.student,
  );

  const testDriver = User(
    id: UserId('driver-1'),
    email: 'driver@sayr.app',
    fullName: 'Driver User',
    role: UserRole.driver,
  );

  final testSubscription = Subscription(
    id: const SubscriptionId('sub-1'),
    studentId: const UserId('student-1'),
    routeId: const RouteId('route-1'),
    status: SubscriptionStatus.active,
    startDate: DateTime(2026),
    endDate: DateTime(2026, 12, 31),
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockSubsBloc = MockSubscriptionsBloc();
    mockNotifsBloc = MockNotificationsBloc();
    mockTrackingBloc = MockTrackingBloc();
    mockRoutesBloc = MockRoutesBloc();
    mockLocaleCubit = MockLocaleCubit();

    // Default stubbing
    when(() => mockSubsBloc.state)
        .thenReturn(SubscriptionsLoaded([testSubscription]));
    when(() => mockNotifsBloc.state).thenReturn(const NotificationsInitial());
    when(() => mockTrackingBloc.state).thenReturn(const TrackingInitial());
    when(() => mockRoutesBloc.state).thenReturn(const RoutesLoaded([]));
    when(() => mockLocaleCubit.state).thenReturn(const Locale('ar'));
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LocaleCubit>.value(value: mockLocaleCubit),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<SubscriptionsBloc>.value(value: mockSubsBloc),
          BlocProvider<NotificationsBloc>.value(value: mockNotifsBloc),
          BlocProvider<TrackingBloc>.value(value: mockTrackingBloc),
          BlocProvider<RoutesBloc>.value(value: mockRoutesBloc),
        ],
        child: child,
      ),
    );
  }

  testWidgets('HomePage renders student tabs when authenticated as student',
      (tester) async {
    when(() => mockAuthBloc.state)
        .thenReturn(const AuthAuthenticated(testStudent));

    await tester.pumpWidget(wrap(const HomePage()));
    await tester.pump();

    // Student should see 5 bottom navigation items:
    // 0: Home, 1: Routes, 2: Active Trips, 3: Subscriptions, 4: Profile
    expect(
        find.byIcon(Icons.home), findsOneWidget,); // selected tab (activeIcon)
    expect(find.byIcon(Icons.directions_bus_outlined), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('HomePage renders driver tabs when authenticated as driver',
      (tester) async {
    when(() => mockAuthBloc.state)
        .thenReturn(const AuthAuthenticated(testDriver));

    await tester.pumpWidget(wrap(const HomePage()));
    await tester.pump();

    // Driver should see 3 bottom navigation items:
    // 0: Home, 1: Active Trips, 2: Profile
    expect(
        find.byIcon(Icons.home), findsOneWidget,); // selected tab (activeIcon)
    expect(find.byIcon(Icons.directions_bus_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    // map_outlined (student tracking map) should NOT be visible for driver home
    expect(find.byIcon(Icons.map_outlined), findsNothing);
  });

  testWidgets('Switching tabs switches screens', (tester) async {
    when(() => mockAuthBloc.state)
        .thenReturn(const AuthAuthenticated(testStudent));

    await tester.pumpWidget(wrap(const HomePage()));
    await tester.pump();

    // Tap on the Routes tab (index 1)
    await tester.tap(find.byIcon(Icons.directions_bus_outlined));
    await tester.pumpAndSettle();

    // Verify it is on the routes page (which renders search bar)
    expect(find.byType(TextField), findsOneWidget);
  });
}
