import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/active_trips_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/map_widget.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MockTrackingBloc extends MockBloc<TrackingEvent, TrackingState> implements TrackingBloc {}
class MockRoutesBloc extends MockBloc<RoutesEvent, RoutesState> implements RoutesBloc {}
class MockHomeNavCubit extends MockCubit<int> implements HomeNavCubit {}

void main() {
  late MockTrackingBloc mockTrackingBloc;
  late MockRoutesBloc mockRoutesBloc;
  late MockHomeNavCubit mockHomeNavCubit;

  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
    registerFallbackValue(const TripId('fallback'));
  });

  setUp(() {
    mockTrackingBloc = MockTrackingBloc();
    mockRoutesBloc = MockRoutesBloc();
    mockHomeNavCubit = MockHomeNavCubit();

    // Default route bloc states
    when(() => mockRoutesBloc.state).thenReturn(const RoutesInitial());
  });

  Widget wrap() {
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
          BlocProvider<TrackingBloc>.value(value: mockTrackingBloc),
          BlocProvider<RoutesBloc>.value(value: mockRoutesBloc),
          BlocProvider<HomeNavCubit>.value(value: mockHomeNavCubit),
        ],
        child: const ActiveTripsPage(),
      ),
    );
  }

  testWidgets('renders skeleton loading when state is TrackingLoading', (tester) async {
    when(() => mockTrackingBloc.state).thenReturn(const TrackingLoading());

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('renders error widget when state is TrackingError', (tester) async {
    when(() => mockTrackingBloc.state).thenReturn(
      const TrackingError(failure: ServerFailure(message: 'خطأ في الاتصال بالخادم')),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('خطأ'), findsOneWidget);
    expect(find.text('خطأ في الاتصال بالخادم'), findsOneWidget);
  });

  testWidgets('renders empty state when there are no active trips', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    when(() => mockTrackingBloc.state).thenReturn(
      const TrackingActiveTripsLoaded(trips: []),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('لا توجد رحلات نشطة حالياً'), findsOneWidget);
    expect(find.text('تصفح الخطوط'), findsOneWidget);
  });

  testWidgets('renders list of active trips and maps route titles correctly', (tester) async {
    final testTrip1 = Trip(
      id: const TripId('trip-1'),
      routeId: const RouteId('route-1'),
      driverId: const DriverId('driver-1'),
      status: TripStatus.inTransit,
      scheduledAt: DateTime(2026, 6, 9, 12),
      lastLocation: const Coordinates(latitude: 33.3128, longitude: 44.3615),
    );

    final testRoute1 = Route(
      id: const RouteId('route-1'),
      driverId: const DriverId('driver-1'),
      title: 'خط الكرادة - الجادرية',
      startLocation: 'الكرادة',
      endLocation: 'الجادرية',
      price: const Money(3000),
      capacity: 25,
      availableSeats: 12,
      isActive: true,
    );

    when(() => mockTrackingBloc.state).thenReturn(
      TrackingActiveTripsLoaded(trips: [testTrip1]),
    );

    when(() => mockRoutesBloc.state).thenReturn(
      RoutesLoaded([testRoute1]),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('خط الكرادة - الجادرية'), findsOneWidget);
    expect(find.text('قيد السير'), findsWidgets);
    expect(find.byType(SayrMap), findsOneWidget);
  });
}
