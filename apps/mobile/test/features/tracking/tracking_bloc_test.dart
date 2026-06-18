import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/driver_location_service.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTripRepository extends Mock implements TripRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDriverLocationService extends Mock implements DriverLocationService {}

class FakeTrackingBloc extends Fake implements TrackingBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
    registerFallbackValue(const TripId('fallback'));
    registerFallbackValue(const DriverId('fallback'));
    registerFallbackValue(const Coordinates(latitude: 0, longitude: 0));
    registerFallbackValue(TripEvent.start);
    registerFallbackValue(FakeTrackingBloc());
  });

  late MockTripRepository mockRepo;
  late MockAuthRepository mockAuth;
  late MockDriverLocationService mockLocationService;
  late TrackingBloc bloc;

  setUp(() {
    sl.allowReassignment = true;
    sl.registerSingleton<Talker>(Talker());

    mockLocationService = MockDriverLocationService();
    when(() => mockLocationService.stopTracking()).thenAnswer((_) async {});
    when(
      () => mockLocationService.startTracking(
        tripId: any(named: 'tripId'),
        trackingBloc: any(named: 'trackingBloc'),
      ),
    ).thenAnswer((_) async {});
    sl.registerSingleton<DriverLocationService>(mockLocationService);

    mockRepo = MockTripRepository();
    mockAuth = MockAuthRepository();
    when(() => mockAuth.currentUser).thenReturn(null);
    bloc = TrackingBloc(
      tripRepository: mockRepo,
      authRepository: mockAuth,
    );
  });

  tearDown(() {
    bloc.close();
    sl.reset();
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
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
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
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
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
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: any(named: 'event'),
            location: any(named: 'location'),
          ),
        ).thenAnswer(
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
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverArrive(
          tripId: TripId('trip-1'),
          location: Coordinates(latitude: 33.3, longitude: 44.3),
        ),
      ),
      expect: () => [
        isA<TrackingDriverActive>().having(
          (s) => s.trip.status,
          'status',
          TripStatus.driverWaiting,
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits [Loading, DriverActive] after creating a trip',
      build: () {
        when(
          () => mockRepo.createTrip(
            routeId: any(named: 'routeId'),
            scheduledAt: any(named: 'scheduledAt'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Trip>(testTrip),
        );
        when(() => mockRepo.watchTrip(any())).thenAnswer(
          (_) => const Stream.empty(),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        TrackingCreateTrip(
          routeId: const RouteId('route-1'),
          scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      ),
      expect: () => [
        isA<TrackingLoading>(),
        isA<TrackingDriverActive>(),
      ],
    );

    // --- Phase 2 Added Tests ---

    blocTest<TrackingBloc, TrackingState>(
      'emits DriverActive with inTransit and isTrackingLocation true after successful start',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.start,
            location: any(named: 'location'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Trip>(
            testTrip.copyWith(status: TripStatus.inTransit),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverStart(
          tripId: TripId('trip-1'),
          location: Coordinates(latitude: 33.3, longitude: 44.3),
        ),
      ),
      expect: () => [
        isA<TrackingDriverActive>()
            .having(
              (s) => s.trip.status,
              'status',
              TripStatus.inTransit,
            )
            .having(
              (s) => s.isTrackingLocation,
              'isTrackingLocation',
              true,
            ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits Error after failed start',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.start,
            location: any(named: 'location'),
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, Trip>(
            ServerFailure(message: 'Failed to start trip'),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverStart(
          tripId: TripId('trip-1'),
          location: Coordinates(latitude: 33.3, longitude: 44.3),
        ),
      ),
      expect: () => [
        isA<TrackingError>(),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits DriverActive with completed status and cancels subscription after successful complete',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.complete,
            location: any(named: 'location'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Trip>(
            testTrip.copyWith(status: TripStatus.completed),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverComplete(
          tripId: TripId('trip-1'),
          location: Coordinates(latitude: 33.3, longitude: 44.3),
        ),
      ),
      expect: () => [
        isA<TrackingDriverActive>().having(
          (s) => s.trip.status,
          'status',
          TripStatus.completed,
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits Error after failed complete',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.complete,
            location: any(named: 'location'),
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, Trip>(
            ServerFailure(message: 'Failed to complete trip'),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverComplete(
          tripId: TripId('trip-1'),
          location: Coordinates(latitude: 33.3, longitude: 44.3),
        ),
      ),
      expect: () => [
        isA<TrackingError>(),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits DriverActive with absent status and cancels subscription after successful markAbsent',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.markAbsent,
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Trip>(
            testTrip.copyWith(status: TripStatus.absent),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverMarkAbsent(
          tripId: TripId('trip-1'),
        ),
      ),
      expect: () => [
        isA<TrackingDriverActive>().having(
          (s) => s.trip.status,
          'status',
          TripStatus.absent,
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits Error after failed markAbsent',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.markAbsent,
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, Trip>(
            ServerFailure(message: 'Failed to mark absent'),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverMarkAbsent(
          tripId: TripId('trip-1'),
        ),
      ),
      expect: () => [
        isA<TrackingError>(),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits DriverActive with cancelled status and cancels subscription after successful cancel',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.cancel,
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Trip>(
            testTrip.copyWith(status: TripStatus.cancelled),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverCancel(
          tripId: TripId('trip-1'),
        ),
      ),
      expect: () => [
        isA<TrackingDriverActive>().having(
          (s) => s.trip.status,
          'status',
          TripStatus.cancelled,
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits Error after failed cancel',
      build: () {
        when(
          () => mockRepo.updateStatus(
            tripId: any(named: 'tripId'),
            event: TripEvent.cancel,
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, Trip>(
            ServerFailure(message: 'Failed to cancel'),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingDriverCancel(
          tripId: TripId('trip-1'),
        ),
      ),
      expect: () => [
        isA<TrackingError>(),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits updated location when in DriverActive state and updateLocation succeeds',
      build: () {
        when(
          () => mockRepo.updateLocation(
            tripId: any(named: 'tripId'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      seed: () => TrackingDriverActive(
        trip: testTrip,
        validActions: const [],
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(
        const TrackingUpdateLocation(
          tripId: TripId('trip-1'),
          latitude: 12.34,
          longitude: 56.78,
        ),
      ),
      expect: () => [
        isA<TrackingDriverActive>().having(
          (s) => s.currentLocation,
          'currentLocation',
          const Coordinates(latitude: 12.34, longitude: 56.78),
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits no new state when in non-DriverActive state and updateLocation succeeds',
      build: () {
        when(
          () => mockRepo.updateLocation(
            tripId: any(named: 'tripId'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      seed: () => const TrackingInitial(),
      act: (bloc) => bloc.add(
        const TrackingUpdateLocation(
          tripId: TripId('trip-1'),
          latitude: 12.34,
          longitude: 56.78,
        ),
      ),
      expect: () => const <TrackingState>[],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits updated location and logs warning when updateLocation fails',
      build: () {
        when(
          () => mockRepo.updateLocation(
            tripId: any(named: 'tripId'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            ServerFailure(message: 'Failed to update location remotely'),
          ),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      seed: () => TrackingDriverActive(
        trip: testTrip,
        validActions: const [],
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(
        const TrackingUpdateLocation(
          tripId: TripId('trip-1'),
          latitude: 12.34,
          longitude: 56.78,
        ),
      ),
      expect: () => [
        isA<TrackingDriverActive>().having(
          (s) => s.currentLocation,
          'currentLocation',
          const Coordinates(latitude: 12.34, longitude: 56.78),
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits TrackingTripWatching states when watched trip yields updates',
      build: () {
        when(() => mockRepo.watchTrip(any())).thenAnswer(
          (_) => Stream.fromIterable([
            testTrip.copyWith(status: TripStatus.driverWaiting),
            testTrip.copyWith(status: TripStatus.inTransit),
          ]),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingWatchTrip(tripId: TripId('trip-1')),
      ),
      expect: () => [
        isA<TrackingTripWatching>().having(
          (s) => s.trip.status,
          'status',
          TripStatus.driverWaiting,
        ),
        isA<TrackingTripWatching>().having(
          (s) => s.trip.status,
          'status',
          TripStatus.inTransit,
        ),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'emits Error when watchTrip yields an error',
      build: () {
        when(() => mockRepo.watchTrip(any())).thenAnswer(
          (_) => Stream.error(Exception('Stream error')),
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) => bloc.add(
        const TrackingWatchTrip(tripId: TripId('trip-1')),
      ),
      expect: () => [
        isA<TrackingError>(),
      ],
    );

    blocTest<TrackingBloc, TrackingState>(
      'cancels subscription and stops yielding updates after TrackingStopWatching',
      build: () {
        final controller = StreamController<Trip>();
        when(() => mockRepo.watchTrip(any())).thenAnswer(
          (_) => controller.stream,
        );
        return TrackingBloc(
          tripRepository: mockRepo,
          authRepository: mockAuth,
        );
      },
      act: (bloc) async {
        bloc.add(const TrackingWatchTrip(tripId: TripId('trip-1')));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TrackingStopWatching());
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => <TrackingState>[],
    );
  });
}
