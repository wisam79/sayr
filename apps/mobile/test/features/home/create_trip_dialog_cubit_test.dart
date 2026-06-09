import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/home/presentation/bloc/create_trip_dialog_cubit.dart';

class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
  });

  late MockRouteRepository mockRepo;
  late CreateTripDialogCubit cubit;

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
    cubit = CreateTripDialogCubit(routeRepository: mockRepo);
  });

  tearDown(() => cubit.close());

  test('initial state has empty routes, null selectedRoute, not submitting',
      () {
    expect(cubit.state.routes, isEmpty);
    expect(cubit.state.selectedRoute, isNull);
    expect(cubit.state.scheduledAt, isNull);
    expect(cubit.state.isSubmitting, isFalse);
    expect(cubit.state.loadingRoutes, isTrue);
    expect(cubit.state.failure, isNull);
  });

  group('loadRoutes', () {
    blocTest<CreateTripDialogCubit, CreateTripDialogState>(
      'emits loaded state with routes on success',
      build: () {
        when(() => mockRepo.getMyDriverRoutes()).thenAnswer(
          (_) async => const Right<Failure, List<Route>>([testRoute]),
        );
        return CreateTripDialogCubit(routeRepository: mockRepo);
      },
      act: (cubit) => cubit.loadRoutes(),
      verify: (cubit) {
        expect(cubit.state.routes, hasLength(1));
        expect(cubit.state.selectedRoute, testRoute);
        expect(cubit.state.loadingRoutes, isFalse);
        expect(cubit.state.failure, isNull);
      },
    );

    blocTest<CreateTripDialogCubit, CreateTripDialogState>(
      'emits error state on failure',
      build: () {
        when(() => mockRepo.getMyDriverRoutes()).thenAnswer(
          (_) async => const Left<Failure, List<Route>>(
            ServerFailure(message: 'network error'),
          ),
        );
        return CreateTripDialogCubit(routeRepository: mockRepo);
      },
      act: (cubit) => cubit.loadRoutes(),
      verify: (cubit) {
        expect(
          cubit.state.failure,
          const ServerFailure(message: 'network error'),
        );
        expect(cubit.state.loadingRoutes, isFalse);
        expect(cubit.state.selectedRoute, isNull);
      },
    );
  });

  group('selectRoute', () {
    blocTest<CreateTripDialogCubit, CreateTripDialogState>(
      'updates selectedRoute',
      build: () => CreateTripDialogCubit(routeRepository: mockRepo),
      seed: () => const CreateTripDialogState(routes: [testRoute]),
      act: (cubit) => cubit.selectRoute(testRoute),
      verify: (cubit) {
        expect(cubit.state.selectedRoute, testRoute);
      },
    );
  });

  group('updateScheduledAt', () {
    blocTest<CreateTripDialogCubit, CreateTripDialogState>(
      'updates scheduledAt and clears error',
      build: () => CreateTripDialogCubit(routeRepository: mockRepo),
      seed: () => const CreateTripDialogState(
        failure: ServerFailure(message: 'old error'),
      ),
      act: (cubit) => cubit.updateScheduledAt(DateTime(2026, 1, 1, 10)),
      verify: (cubit) {
        expect(cubit.state.scheduledAt, DateTime(2026, 1, 1, 10));
        expect(cubit.state.failure, isNull);
      },
    );
  });

  group('setSubmitting / setError', () {
    blocTest<CreateTripDialogCubit, CreateTripDialogState>(
      'setSubmitting(true) sets isSubmitting and clears error',
      build: () => CreateTripDialogCubit(routeRepository: mockRepo),
      seed: () =>
          const CreateTripDialogState(failure: ServerFailure(message: 'old')),
      act: (cubit) => cubit.setSubmitting(isSubmitting: true),
      verify: (cubit) {
        expect(cubit.state.isSubmitting, isTrue);
        expect(cubit.state.failure, isNull);
      },
    );

    blocTest<CreateTripDialogCubit, CreateTripDialogState>(
      'setError sets error message and stops submitting',
      build: () => CreateTripDialogCubit(routeRepository: mockRepo),
      seed: () => const CreateTripDialogState(isSubmitting: true),
      act: (cubit) => cubit.setError(const ServerFailure(message: 'boom')),
      verify: (cubit) {
        expect(cubit.state.failure, const ServerFailure(message: 'boom'));
        expect(cubit.state.isSubmitting, isFalse);
      },
    );
  });
}
