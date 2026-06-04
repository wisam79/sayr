import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepo;
  late TrackingBloc bloc;

  setUp(() {
    mockRepo = MockTripRepository();
    bloc = TrackingBloc(tripRepository: mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  final testTrip = Trip(
    id: const TripId('trip-1'),
    routeId: const RouteId('route-1'),
    driverId: const DriverId('driver-1'),
    status: TripStatus.scheduled,
    scheduledAt: DateTime.now().add(const Duration(hours: 1)),
  );

  group('TrackingBloc', () {
    test('initial state is TrackingInitial', () {
      expect(bloc.state, isA<TrackingInitial>());
    });

    blocTest<TrackingBloc, TrackingState>(
      'emits [Loading, ActiveTripsLoaded] when load succeeds',
      build: () {
        when(() => mockRepo.getActiveTrips()).thenAnswer(
          (_) async => Right<Failure, List<Trip>>([testTrip]),
        );
        return TrackingBloc(tripRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const TrackingLoadActiveTrips()),
      expect: () => [
        isA<TrackingLoading>(),
        isA<TrackingActiveTripsLoaded>().having(
          (s) => s.trips.length,
          'trips',
          1,
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits [Loading, Error] when load fails',
      build: () {
        when(() => mockRepo.getActiveTrips()).thenAnswer(
          (_) async => const Left<Failure, List<Trip>>(
            ServerFailure(message: 'Server error'),
          ),
        );
        return TrackingBloc(tripRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const TrackingLoadActiveTrips()),
      expect: () => [
        isA<TrackingLoading>(),
        isA<TrackingError>(),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits DriverActive after successful arrive',
      build: () {
        when(() => mockRepo.getActiveTrips()).thenAnswer(
          (_) async => Right<Failure, List<Trip>>([testTrip]),
        );
        when(() => mockRepo.getById(any())).thenAnswer(
          (_) async => Right<Failure, Trip>(testTrip),
        );
        when(() => mockRepo.updateStatus(
              tripId: any(named: 'tripId'),
              event: any(named: 'event'),
              location: any(named: 'location'),
            )).thenAnswer(
          (_) async => Right<Failure, Trip>(
            Trip(
              id: const TripId('trip-1'),
              routeId: const RouteId('route-1'),
              driverId: const DriverId('driver-1'),
              status: TripStatus.driverWaiting,
              scheduledAt: DateTime.now().add(const Duration(hours: 1)),
            ),
          ),
        );
        when(() => mockRepo.watchTrip(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
        return TrackingBloc(tripRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const TrackingDriverArrive(
        tripId: TripId('trip-1'),
        location: Coordinates(latitude: 33.3, longitude: 44.3),
      )),
      expect: () => [
        isA<TrackingDriverActive>().having(
          (s) => s.trip.status,
          'status',
          TripStatus.driverWaiting,
        ),
      ],
    );
  });
}
