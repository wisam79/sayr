import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/osrm_service.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_ui_cubit.dart';

class MockOsrmService extends Mock implements OsrmService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  late MockOsrmService mockOsrm;
  late TrackingUiCubit cubit;

  setUp(() {
    sl.allowReassignment = true;
    mockOsrm = MockOsrmService();
    sl.registerSingleton<OsrmService>(mockOsrm);
    cubit = TrackingUiCubit();
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
          isFetchingRoute: false,
          routePoints: [LatLng(1.0, 2.0), LatLng(3.0, 4.0)],
          loadedRouteId: RouteId('route-1'),
          isApproximate: false,
        ),
      ],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'fetchRoutePath calls OSRM and emits points on success',
      build: () {
        when(() => mockOsrm.getRoute(any(), any())).thenAnswer(
          (_) async => const [LatLng(1.1, 2.1), LatLng(3.1, 4.1)],
        );
        return cubit;
      },
      act: (cubit) => cubit.fetchRoutePath(
        start: const Coordinates(latitude: 1.0, longitude: 2.0),
        end: const Coordinates(latitude: 3.0, longitude: 4.0),
        routeId: const RouteId('route-1'),
      ),
      expect: () => [
        const TrackingUiState(isFetchingRoute: true),
        const TrackingUiState(
          isFetchingRoute: false,
          routePoints: [LatLng(1.1, 2.1), LatLng(3.1, 4.1)],
          loadedRouteId: RouteId('route-1'),
          isApproximate: false,
        ),
      ],
    );

    blocTest<TrackingUiCubit, TrackingUiState>(
      'fetchRoutePath falls back to straight line on OSRM error',
      build: () {
        when(() => mockOsrm.getRoute(any(), any())).thenThrow(
          Exception('OSRM error'),
        );
        return cubit;
      },
      act: (cubit) => cubit.fetchRoutePath(
        start: const Coordinates(latitude: 1.0, longitude: 2.0),
        end: const Coordinates(latitude: 3.0, longitude: 4.0),
        routeId: const RouteId('route-1'),
      ),
      expect: () => [
        const TrackingUiState(isFetchingRoute: true),
        const TrackingUiState(
          isFetchingRoute: false,
          routePoints: [LatLng(1.0, 2.0), LatLng(3.0, 4.0)],
          loadedRouteId: RouteId('route-1'),
          isApproximate: true,
        ),
      ],
    );
  });
}
