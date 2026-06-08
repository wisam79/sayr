import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/route_details_cubit.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/route_details_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  late MockRouteRepository mockRepo;
  late RouteDetailsCubit detailsCubit;

  const testRoute = Route(
    id: RouteId('route-1'),
    driverId: DriverId('driver-1'),
    title: 'Baghdad - Basra',
    startLocation: 'Baghdad',
    endLocation: 'Basra',
    price: Money(5000),
    capacity: 40,
    availableSeats: 30,
    isActive: true,
  );

  setUp(() {
    mockRepo = MockRouteRepository();
    detailsCubit = RouteDetailsCubit(routeRepository: mockRepo);
    registerFallbackValue(const RouteId('route-1'));
  });

  tearDown(() => detailsCubit.close());

  Widget wrap(Widget child, {RouteDetailsCubit? cubit}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: cubit != null
          ? BlocProvider<RouteDetailsCubit>.value(
              value: cubit,
              child: child,
            )
          : child,
    );
  }

  testWidgets('Directly passed Route object renders details correctly',
      (tester) async {
    await tester.pumpWidget(wrap(const RouteDetailsPage(route: testRoute)));
    await tester.pumpAndSettle();

    expect(find.text('Baghdad - Basra'), findsWidgets);
    expect(find.text('Baghdad → Basra'), findsOneWidget);
    expect(find.text('5,000 د.ع'), findsOneWidget);
    expect(find.text('30 / 40'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'اشترك الآن'), findsOneWidget);
  });

  testWidgets('Tapping Subscribe shows Zain Cash and License options sheet',
      (tester) async {
    await tester.pumpWidget(wrap(const RouteDetailsPage(route: testRoute)));
    await tester.pumpAndSettle();

    final subscribeBtn = find.widgetWithText(PrimaryButton, 'اشترك الآن');
    await tester.tap(subscribeBtn);
    await tester.pumpAndSettle();

    expect(find.text('اختر طريقة الدفع'), findsOneWidget);
    expect(find.text('تفعيل ترخيص'), findsOneWidget);
    expect(find.text('الدفع عبر زين كاش'), findsOneWidget);
  });
}
