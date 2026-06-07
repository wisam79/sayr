import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/routes_list_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockRoutesBloc extends MockBloc<RoutesEvent, RoutesState>
    implements RoutesBloc {}

void main() {
  late MockRoutesBloc mockRoutesBloc;

  final testRoutes = [
    const Route(
      id: RouteId('route-1'),
      driverId: DriverId('driver-1'),
      title: 'Baghdad - Basra',
      startLocation: 'Baghdad',
      endLocation: 'Basra',
      price: Money(5000),
      capacity: 40,
      availableSeats: 30,
      isActive: true,
    ),
  ];

  setUp(() {
    mockRoutesBloc = MockRoutesBloc();
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
      home: BlocProvider<RoutesBloc>.value(
        value: mockRoutesBloc,
        child: child,
      ),
    );
  }

  testWidgets('RoutesListPage shows skeleton when loading', (tester) async {
    when(() => mockRoutesBloc.state).thenReturn(const RoutesLoading());

    await tester.pumpWidget(wrap(const RoutesListPage()));
    // Skeletonizer is active during RoutesLoading.
    expect(find.text('Baghdad University Campus Route'), findsWidgets);
  });

  testWidgets('RoutesListPage shows routes list on load success',
      (tester) async {
    when(() => mockRoutesBloc.state).thenReturn(RoutesLoaded(testRoutes));

    await tester.pumpWidget(wrap(const RoutesListPage()));
    await tester.pump();

    expect(find.text('Baghdad - Basra'), findsOneWidget);
    expect(find.text('Baghdad'), findsOneWidget);
    expect(find.text('Basra'), findsOneWidget);
  });

  testWidgets('RoutesListPage shows empty state when list is empty',
      (tester) async {
    when(() => mockRoutesBloc.state).thenReturn(const RoutesLoaded([]));

    await tester.pumpWidget(wrap(const RoutesListPage()));
    await tester.pump();

    expect(find.text('لا توجد خطوط متاحة'), findsOneWidget);
  });

  testWidgets('RoutesListPage shows error state and calls retry',
      (tester) async {
    when(() => mockRoutesBloc.state).thenReturn(
      const RoutesError(ServerFailure(message: 'Connection error')),
    );

    await tester.pumpWidget(wrap(const RoutesListPage()));
    await tester.pump();

    expect(find.text('Connection error'), findsOneWidget);
    final retryBtn = find.text('إعادة المحاولة');
    expect(retryBtn, findsOneWidget);

    await tester.tap(retryBtn);
    await tester.pump();

    verify(() => mockRoutesBloc.add(const RoutesLoadRequested())).called(2);
  });

  testWidgets('Typing in search bar dispatches search event', (tester) async {
    when(() => mockRoutesBloc.state).thenReturn(RoutesLoaded(testRoutes));

    await tester.pumpWidget(wrap(const RoutesListPage()));
    await tester.pump();

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Basra');
    await tester.pump();

    verify(() => mockRoutesBloc.add(const RoutesSearchRequested('Basra')))
        .called(1);
  });
}
