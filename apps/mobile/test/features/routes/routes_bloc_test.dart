import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';

class MockRouteRepository extends Mock implements RouteRepository {}

void main() {
  late MockRouteRepository mockRepo;
  late RoutesBloc bloc;

  setUp(() {
    mockRepo = MockRouteRepository();
    bloc = RoutesBloc(routeRepository: mockRepo);
  });

  tearDown(() => bloc.close());

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

  group('RoutesBloc', () {
    test('initial state is RoutesInitial', () {
      expect(bloc.state, isA<RoutesInitial>());
    });

    blocTest<RoutesBloc, RoutesState>(
      'emits [Loading, Loaded] on load success',
      build: () {
        when(() => mockRepo.getActiveRoutes()).thenAnswer(
          (_) async => Right<Failure, ({List<Route> routes, bool fromCache})>(
            (routes: testRoutes, fromCache: false),
          ),
        );
        return RoutesBloc(routeRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const RoutesLoadRequested()),
      expect: () => [
        isA<RoutesLoading>(),
        isA<RoutesLoaded>().having((s) => s.routes.length, 'routes', 1),
      ],
    );

    blocTest<RoutesBloc, RoutesState>(
      'emits [Loading, Error] on load failure',
      build: () {
        when(() => mockRepo.getActiveRoutes()).thenAnswer(
          (_) async =>
              const Left<Failure, ({List<Route> routes, bool fromCache})>(
            ServerFailure(message: 'Server error'),
          ),
        );
        return RoutesBloc(routeRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const RoutesLoadRequested()),
      expect: () => [
        isA<RoutesLoading>(),
        isA<RoutesError>(),
      ],
    );

    blocTest<RoutesBloc, RoutesState>(
      'emits [Loading, Loaded] on search success with results',
      build: () {
        when(() => mockRepo.search('Basra')).thenAnswer(
          (_) async => Right<Failure, List<Route>>(testRoutes),
        );
        return RoutesBloc(routeRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const RoutesSearchRequested('Basra')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<RoutesLoading>(),
        isA<RoutesLoaded>(),
      ],
    );

    blocTest<RoutesBloc, RoutesState>(
      'emits [Loading, Error] on search failure',
      build: () {
        when(() => mockRepo.search('xyz')).thenAnswer(
          (_) async => const Left<Failure, List<Route>>(
            ServerFailure(message: 'Search failed'),
          ),
        );
        return RoutesBloc(routeRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const RoutesSearchRequested('xyz')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<RoutesLoading>(),
        isA<RoutesError>(),
      ],
    );

    blocTest<RoutesBloc, RoutesState>(
      'dispatches RoutesLoadRequested when query is empty',
      build: () {
        when(() => mockRepo.getActiveRoutes()).thenAnswer(
          (_) async => Right<Failure, ({List<Route> routes, bool fromCache})>(
            (routes: testRoutes, fromCache: false),
          ),
        );
        return RoutesBloc(routeRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const RoutesSearchRequested('')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<RoutesLoading>(),
        isA<RoutesLoaded>(),
      ],
    );

    blocTest<RoutesBloc, RoutesState>(
      'dispatches RoutesLoadRequested when query is only whitespace',
      build: () {
        when(() => mockRepo.getActiveRoutes()).thenAnswer(
          (_) async => Right<Failure, ({List<Route> routes, bool fromCache})>(
            (routes: testRoutes, fromCache: false),
          ),
        );
        return RoutesBloc(routeRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const RoutesSearchRequested('   ')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<RoutesLoading>(),
        isA<RoutesLoaded>(),
      ],
    );

    blocTest<RoutesBloc, RoutesState>(
      'search trims whitespace from query',
      build: () {
        when(() => mockRepo.search('Basra')).thenAnswer(
          (_) async => Right<Failure, List<Route>>(testRoutes),
        );
        return RoutesBloc(routeRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const RoutesSearchRequested('  Basra  ')),
      wait: const Duration(milliseconds: 500),
      verify: (_) => verify(() => mockRepo.search('Basra')).called(1),
    );
  });
}
