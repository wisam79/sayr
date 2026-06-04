import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_state.dart';

class MockEmergencyRepository extends Mock implements EmergencyRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(TripId('fallback'));
    registerFallbackValue(RouteId('fallback'));
    registerFallbackValue(EmergencyReportId('fallback'));
    registerFallbackValue(Coordinates(latitude: 0, longitude: 0));
  });

  late MockEmergencyRepository mockRepo;
  late EmergencyBloc bloc;

  setUp(() {
    mockRepo = MockEmergencyRepository();
    bloc = EmergencyBloc(emergencyRepository: mockRepo);
  });

  tearDown(() => bloc.close());

  final testReport = EmergencyReport(
    id: const EmergencyReportId('report-1'),
    userId: const UserId('user-1'),
    tripId: const TripId('trip-1'),
    location: const Coordinates(latitude: 33.3, longitude: 44.3),
    createdAt: DateTime.now(),
  );

  group('EmergencyBloc', () {
    test('initial state is EmergencyIdle', () {
      expect(bloc.state, isA<EmergencyIdle>());
    });

    blocTest<EmergencyBloc, EmergencyState>(
      'emits [Sending, Active] on trigger success',
      build: () {
        when(() => mockRepo.triggerEmergency(
              tripId: any(named: 'tripId'),
              routeId: any(named: 'routeId'),
              location: any(named: 'location'),
              message: any(named: 'message'),
            )).thenAnswer(
          (_) async => Right<Failure, EmergencyReport>(testReport),
        );
        return EmergencyBloc(emergencyRepository: mockRepo);
      },
      act: (bloc) => bloc.add(EmergencyTriggered(
        tripId: const TripId('trip-1'),
        routeId: const RouteId('route-1'),
        location: const Coordinates(latitude: 33.3, longitude: 44.3),
      )),
      expect: () => [
        isA<EmergencySending>(),
        isA<EmergencyActive>(),
      ],
    );

    blocTest<EmergencyBloc, EmergencyState>(
      'emits [Sending, Failed] on trigger failure',
      build: () {
        when(() => mockRepo.triggerEmergency(
              tripId: any(named: 'tripId'),
              routeId: any(named: 'routeId'),
              location: any(named: 'location'),
              message: any(named: 'message'),
            )).thenAnswer(
          (_) async => const Left<Failure, EmergencyReport>(
            ServerFailure(message: 'Failed'),
          ),
        );
        return EmergencyBloc(emergencyRepository: mockRepo);
      },
      act: (bloc) => bloc.add(EmergencyTriggered(
        tripId: const TripId('trip-1'),
        routeId: const RouteId('route-1'),
        location: const Coordinates(latitude: 33.3, longitude: 44.3),
      )),
      expect: () => [
        isA<EmergencySending>(),
        isA<EmergencyFailed>(),
      ],
    );

    blocTest<EmergencyBloc, EmergencyState>(
      'emits [Sending, Idle] on cancel success when Active',
      build: () {
        when(() => mockRepo.resolveReport(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        return EmergencyBloc(emergencyRepository: mockRepo);
      },
      seed: () => EmergencyActive(report: testReport),
      act: (bloc) => bloc.add(const EmergencyCancelled()),
      expect: () => [
        isA<EmergencySending>(),
        isA<EmergencyIdle>(),
      ],
    );

    blocTest<EmergencyBloc, EmergencyState>(
      'does nothing when state is not Active',
      build: () => EmergencyBloc(emergencyRepository: mockRepo),
      act: (bloc) => bloc.add(const EmergencyCancelled()),
      expect: () => <EmergencyState>[],
    );

    blocTest<EmergencyBloc, EmergencyState>(
      'EmergencyReset emits Idle',
      build: () => EmergencyBloc(emergencyRepository: mockRepo),
      seed: () => EmergencyActive(report: testReport),
      act: (bloc) => bloc.add(const EmergencyReset()),
      expect: () => [isA<EmergencyIdle>()],
    );

    blocTest<EmergencyBloc, EmergencyState>(
      'trigger then cancel returns to Idle',
      build: () {
        when(() => mockRepo.triggerEmergency(
              tripId: any(named: 'tripId'),
              routeId: any(named: 'routeId'),
              location: any(named: 'location'),
              message: any(named: 'message'),
            )).thenAnswer(
          (_) async => Right<Failure, EmergencyReport>(testReport),
        );
        when(() => mockRepo.resolveReport(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        return EmergencyBloc(emergencyRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(EmergencyTriggered(
          tripId: const TripId('trip-1'),
          routeId: const RouteId('route-1'),
          location: const Coordinates(latitude: 33.3, longitude: 44.3),
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EmergencyCancelled());
      },
      expect: () => [
        isA<EmergencySending>(),
        isA<EmergencyActive>(),
        isA<EmergencySending>(),
        isA<EmergencyIdle>(),
      ],
    );
  });
}
