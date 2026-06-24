import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_ui_cubit.dart';

class MockRoutingService extends Mock implements RoutingService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(const Coordinates(latitude: 0, longitude: 0));
  });

  late MockRoutingService mockRouting;
  late TrackingUiCubit cubit;

  setUp(() {
    sl.allowReassignment = true;
    mockRouting = MockRoutingService();
    sl.registerSingleton<RoutingService>(mockRouting);
    cubit = TrackingUiCubit(routingService: mockRouting);
  });

  tearDown(() {
    cubit.close();
    sl.reset();
  });

  group('TrackingUiCubit', () {
    test('initial state is correct', () {
      expect(cubit.state, equals(TrackingUiState.initial));
    });

    blocTest<TrackingUiCubit, TrackingUiState>(
      'markRatingShown emits state with ratingShown true',
      build: () => cubit,
      act: (cubit) => cubit.markRatingShown(),
      expect: () => [
        const TrackingUiState(ratingShown: true),
      ],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'reset emits initial state',
      build: () => cubit,
      seed: () => const TrackingUiState(ratingShown: true, isApproximate: true),
      act: (cubit) => cubit.reset(),
      expect: () => [
        TrackingUiState.initial,
      ],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'fetchRoutePath returns early and does not emit if already loaded',
      build: () => cubit,
      seed: () => const TrackingUiState(
        routePoints: [LatLng(1, 2)],
        loadedRouteId: RouteId('route-1'),
      ),
      act: (cubit) => cubit.fetchRoutePath(
        start: const Coordinates(latitude: 1, longitude: 2),
        end: const Coordinates(latitude: 3, longitude: 4),
        routeId: const RouteId('route-1'),
      ),
      expect: () => <TrackingUiState>[],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'fetchRoutePath parses and uses routeGeometry when provided',
      build: () => cubit,
      act: (cubit) => cubit.fetchRoutePath(
        start: const Coordinates(latitude: 1, longitude: 2),
        end: const Coordinates(latitude: 3, longitude: 4),
        routeId: const RouteId('route-1'),
        routeGeometry: '[[2.0, 1.0], [4.0, 3.0]]',
      ),
      expect: () => [
        const TrackingUiState(
          routePoints: [LatLng(1, 2), LatLng(3, 4)],
          loadedRouteId: RouteId('route-1'),
        ),
      ],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'fetchRoutePath calls RoutingService and emits points on success',
      build: () {
        when(() => mockRouting.getRoute(any(), any())).thenAnswer(
          (_) async => const Right([
            Coordinates(latitude: 1.1, longitude: 2.1),
            Coordinates(latitude: 3.1, longitude: 4.1),
          ]),
        );
        return cubit;
      },
      act: (cubit) => cubit.fetchRoutePath(
        start: const Coordinates(latitude: 1, longitude: 2),
        end: const Coordinates(latitude: 3, longitude: 4),
        routeId: const RouteId('route-1'),
      ),
      expect: () => [
        const TrackingUiState(isFetchingRoute: true),
        const TrackingUiState(
          routePoints: [LatLng(1.1, 2.1), LatLng(3.1, 4.1)],
          loadedRouteId: RouteId('route-1'),
        ),
      ],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'fetchRoutePath falls back to straight line on RoutingService failure',
      build: () {
        when(() => mockRouting.getRoute(any(), any())).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'Routing failure')),
        );
        return cubit;
      },
      act: (cubit) => cubit.fetchRoutePath(
        start: const Coordinates(latitude: 1, longitude: 2),
        end: const Coordinates(latitude: 3, longitude: 4),
        routeId: const RouteId('route-1'),
      ),
      expect: () => [
        const TrackingUiState(isFetchingRoute: true),
        const TrackingUiState(
          routePoints: [LatLng(1, 2), LatLng(3, 4)],
          loadedRouteId: RouteId('route-1'),
          isApproximate: true,
        ),
      ],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'fetchRoutePath falls back to straight line on RoutingService exception',
      build: () {
        when(() => mockRouting.getRoute(any(), any())).thenThrow(
          Exception('Routing exception'),
        );
        return cubit;
      },
      act: (cubit) => cubit.fetchRoutePath(
        start: const Coordinates(latitude: 1, longitude: 2),
        end: const Coordinates(latitude: 3, longitude: 4),
        routeId: const RouteId('route-1'),
      ),
      expect: () => [
        const TrackingUiState(isFetchingRoute: true),
        const TrackingUiState(
          routePoints: [LatLng(1, 2), LatLng(3, 4)],
          loadedRouteId: RouteId('route-1'),
          isApproximate: true,
        ),
      ],
    );
  });
}
