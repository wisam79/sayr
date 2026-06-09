import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/routes/presentation/bloc/route_details_cubit.dart';

class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
  });

  late MockRouteRepository mockRepo;
  late RouteDetailsCubit cubit;

  const testRoute = Route(
    id: RouteId('route-1'),
    driverId: DriverId('driver-1'),
    title: 'Test Route',
    startLocation: 'Start',
    endLocation: 'End',
    price: Money(1000),
    capacity: 30,
    availableSeats: 25,
    isActive: true,
  );

  setUp(() {
    mockRepo = MockRouteRepository();
    cubit = RouteDetailsCubit(routeRepository: mockRepo);
  });

  tearDown(() => cubit.close());

  test('initial state is RouteDetailsInitial', () {
    expect(cubit.state, isA<RouteDetailsInitial>());
  });

  blocTest<RouteDetailsCubit, RouteDetailsState>(
    'loadRoute emits Loading then Loaded on success',
    build: () {
      when(() => mockRepo.getById(any())).thenAnswer(
        (_) async => const Right<Failure, Route>(testRoute),
      );
      return RouteDetailsCubit(routeRepository: mockRepo);
    },
    act: (cubit) => cubit.loadRoute(const RouteId('route-1')),
    expect: () => [
      isA<RouteDetailsLoading>(),
      isA<RouteDetailsLoaded>(),
    ],
    verify: (cubit) {
      final state = cubit.state as RouteDetailsLoaded;
      expect(state.route, testRoute);
    },
  );

  blocTest<RouteDetailsCubit, RouteDetailsState>(
    'loadRoute emits Loading then Error on failure',
    build: () {
      when(() => mockRepo.getById(any())).thenAnswer(
        (_) async => const Left<Failure, Route>(
          ServerFailure(message: 'not found'),
        ),
      );
      return RouteDetailsCubit(routeRepository: mockRepo);
    },
    act: (cubit) => cubit.loadRoute(const RouteId('route-1')),
    expect: () => [
      isA<RouteDetailsLoading>(),
      isA<RouteDetailsError>(),
    ],
    verify: (cubit) {
      final state = cubit.state as RouteDetailsError;
      expect(state.failure, const ServerFailure(message: 'not found'));
    },
  );

  blocTest<RouteDetailsCubit, RouteDetailsState>(
    'setRoute emits Loaded with the provided route',
    build: () => RouteDetailsCubit(routeRepository: mockRepo),
    act: (cubit) => cubit.setRoute(testRoute),
    expect: () => [isA<RouteDetailsLoaded>()],
    verify: (cubit) {
      expect((cubit.state as RouteDetailsLoaded).route, testRoute);
    },
  );
}
