import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockSubscriptionsBloc
    extends MockBloc<SubscriptionsEvent, SubscriptionsState>
    implements SubscriptionsBloc {}

void main() {
  late MockSubscriptionsBloc mockBloc;

  setUp(() {
    mockBloc = MockSubscriptionsBloc();
  });

  final pastDate = DateTime.now().subtract(const Duration(days: 30));
  final futureDate = DateTime.now().add(const Duration(days: 60));

  final activeSub = Subscription(
    id: const SubscriptionId('sub-1'),
    studentId: const UserId('student-1'),
    routeId: const RouteId('route-1'),
    status: SubscriptionStatus.active,
    startDate: pastDate,
    endDate: futureDate,
  );

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
      home: BlocProvider<SubscriptionsBloc>.value(
        value: mockBloc,
        child: child,
      ),
    );
  }

  testWidgets('shows loading widget when state is SubscriptionsLoading',
      (tester) async {
    when(() => mockBloc.state).thenReturn(const SubscriptionsLoading());

    await tester.pumpWidget(wrap(const MySubscriptionsPage()));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString().contains('Skeleton'),
      ),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('shows empty state when no subscriptions', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const SubscriptionsLoaded([]),
    );

    await tester.pumpWidget(wrap(const MySubscriptionsPage()));
    await tester.pump();

    expect(find.text('لا يوجد اشتراكات'), findsOneWidget);
  });

  testWidgets('shows subscription list when loaded', (tester) async {
    when(() => mockBloc.state).thenReturn(
      SubscriptionsLoaded([activeSub]),
    );

    await tester.pumpWidget(wrap(const MySubscriptionsPage()));
    await tester.pump();

    expect(find.text('نشط'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('shows error state with retry', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const SubscriptionsError(ServerFailure(message: 'Server error')),
    );

    await tester.pumpWidget(wrap(const MySubscriptionsPage()));
    await tester.pump();

    expect(find.text('Server error'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
