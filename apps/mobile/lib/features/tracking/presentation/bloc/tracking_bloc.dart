import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/driver_location_service.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// BLoC for trip tracking — student view and driver controls.
///
/// Student: loads active trips on map, watches a specific trip.
/// Driver: manages trip lifecycle (arrive/start/complete/cancel) and streams location.
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  /// Creates a [TrackingBloc] with the given [tripRepository] and [authRepository].
  TrackingBloc({
    required TripRepository tripRepository,
    required AuthRepository authRepository,
    DriverLocationService? driverLocationService,
  })  : _tripRepository = tripRepository,
        _authRepository = authRepository,
        _driverLocationService =
            driverLocationService ?? sl<DriverLocationService>(),
        super(const TrackingState.initial()) {
    on<TrackingLoadActiveTrips>(_onLoadActiveTrips);
    on<TrackingWatchTrip>(_onWatchTrip);
    on<TrackingStopWatching>(_onStopWatching);
    on<TrackingDriverArrive>(_onDriverArrive);
    on<TrackingDriverStart>(_onDriverStart);
    on<TrackingDriverComplete>(_onDriverComplete);
    on<TrackingDriverMarkAbsent>(_onDriverMarkAbsent);
    on<TrackingDriverCancel>(_onDriverCancel);
    on<TrackingUpdateLocation>(_onUpdateLocation);
    on<TrackingCreateTrip>(_onCreateTrip);
    on<_TripUpdated>(_onTripUpdated);
    on<_TripUpdateError>(_onTripUpdateError);
  }

  final TripRepository _tripRepository;
  final AuthRepository _authRepository;
  final DriverLocationService _driverLocationService;
  StreamSubscription<Trip>? _tripSubscription;

  @override
  Future<void> close() async {
    await _tripSubscription?.cancel();
    // Release the GPS stream so the foreground service stops when the bloc
    // (and therefore the tracking session) is torn down.
    await _driverLocationService.stopTracking();
    return super.close();
  }

  Future<void> _onLoadActiveTrips(
    TrackingLoadActiveTrips event,
    Emitter<TrackingState> emit,
  ) async {
    emit(const TrackingState.loading());
    final result = await _tripRepository.getActiveTrips();
    if (isClosed) return;
    result.fold(
      (failure) => emit(TrackingState.error(failure: failure)),
      (trips) => emit(TrackingState.activeTripsLoaded(trips: trips)),
    );
  }

  Future<void> _onCreateTrip(
    TrackingCreateTrip event,
    Emitter<TrackingState> emit,
  ) async {
    emit(const TrackingState.loading());
    final result = await _tripRepository.createTrip(
      routeId: event.routeId,
      scheduledAt: event.scheduledAt,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(TrackingState.error(failure: failure)),
      (trip) {
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(
          TrackingState.driverActive(
            trip: trip,
            validActions: actions,
            lastUpdated: DateTime.now(),
          ),
        );
        add(TrackingWatchTrip(tripId: trip.id));
      },
    );
  }

  Future<void> _onWatchTrip(
    TrackingWatchTrip event,
    Emitter<TrackingState> emit,
  ) async {
    await _tripSubscription?.cancel();

    final current = state;
    if (current is TrackingActiveTripsLoaded) {
      Trip? trip;
      for (final t in current.trips) {
        if (t.id == event.tripId) {
          trip = t;
          break;
        }
      }
      if (trip != null) {
        emit(
          TrackingState.tripWatching(
            trip: trip,
            driverLocation: trip.lastLocation,
          ),
        );
      }
    }

    _tripSubscription = _tripRepository.watchTrip(event.tripId).listen(
      (trip) {
        if (!isClosed) {
          add(_TripUpdated(trip));
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          add(_TripUpdateError(error));
        }
      },
    );
  }

  void _onStopWatching(
    TrackingStopWatching event,
    Emitter<TrackingState> emit,
  ) {
    unawaited(_tripSubscription?.cancel());
    _tripSubscription = null;
  }

  void _onTripUpdated(_TripUpdated event, Emitter<TrackingState> emit) {
    final current = state;

    switch (current) {
      case TrackingTripWatching(:final trip) when trip.id == event.trip.id:
        return _emitTripWatching(emit, event.trip, event.trip.lastLocation);

      case TrackingDriverActive(
            :final trip,
            :final currentLocation,
            :final isTrackingLocation,
          )
          when trip.id == event.trip.id:
        return _emitDriverActive(
          emit,
          event.trip,
          currentLocation: currentLocation,
          isTrackingLocation: isTrackingLocation,
        );

      case TrackingInitial() || TrackingLoading():
        final currentUser = _authRepository.currentUser;
        final isDriver = currentUser != null &&
            currentUser.id.value == event.trip.driverId.value;

        if (isDriver) {
          return _emitDriverActive(emit, event.trip);
        } else {
          return _emitTripWatching(emit, event.trip, event.trip.lastLocation);
        }

      default:
        break;
    }
  }

  void _emitTripWatching(
    Emitter<TrackingState> emit,
    Trip trip,
    Coordinates? driverLocation,
  ) {
    emit(
      TrackingState.tripWatching(
        trip: trip,
        driverLocation: driverLocation,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void _emitDriverActive(
    Emitter<TrackingState> emit,
    Trip trip, {
    Coordinates? currentLocation,
    bool isTrackingLocation = false,
  }) {
    final actions = TripStateMachine.validEventsFrom(trip.status);
    emit(
      TrackingState.driverActive(
        trip: trip,
        validActions: actions,
        currentLocation: currentLocation,
        isTrackingLocation: isTrackingLocation,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void _onTripUpdateError(
    _TripUpdateError event,
    Emitter<TrackingState> emit,
  ) {
    emit(
      TrackingState.error(
        failure: UnknownFailure(message: event.error.toString()),
        previousState: state,
      ),
    );
  }

  Future<void> _onDriverAction(
    TripEvent action,
    TripId tripId,
    Coordinates? location,
    Emitter<TrackingState> emit, {
    bool cancelsSubscription = false,
    bool activatesTracking = false,
  }) async {
    final result = await _tripRepository.updateStatus(
      tripId: tripId,
      event: action,
      location: location,
    );

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(
        TrackingState.error(
          failure: failure,
          previousState: state,
        ),
      ),
      (trip) async {
        if (cancelsSubscription) {
          await _tripSubscription?.cancel();
          // Trip is over — stop streaming the driver's location.
          await _driverLocationService.stopTracking();
        }
        if (activatesTracking) {
          // Trip is now in progress — start the GPS stream, decoupled from the
          // page lifecycle so it survives backgrounding the app.
          try {
            await _driverLocationService.startTracking(
              tripId: trip.id,
              trackingBloc: this,
            );
          } catch (e) {
            sl<Talker>().warning(
              'TrackingBloc: could not start driver location stream: $e',
            );
          }
        }
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(
          TrackingState.driverActive(
            trip: trip,
            validActions: actions,
            currentLocation: location ?? trip.lastLocation,
            isTrackingLocation: activatesTracking,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onDriverArrive(
    TrackingDriverArrive event,
    Emitter<TrackingState> emit,
  ) =>
      _onDriverAction(TripEvent.arrive, event.tripId, event.location, emit);

  Future<void> _onDriverStart(
    TrackingDriverStart event,
    Emitter<TrackingState> emit,
  ) =>
      _onDriverAction(
        TripEvent.start,
        event.tripId,
        event.location,
        emit,
        activatesTracking: true,
      );

  Future<void> _onDriverComplete(
    TrackingDriverComplete event,
    Emitter<TrackingState> emit,
  ) =>
      _onDriverAction(
        TripEvent.complete,
        event.tripId,
        event.location,
        emit,
        cancelsSubscription: true,
      );

  Future<void> _onDriverMarkAbsent(
    TrackingDriverMarkAbsent event,
    Emitter<TrackingState> emit,
  ) =>
      _onDriverAction(
        TripEvent.markAbsent,
        event.tripId,
        null,
        emit,
        cancelsSubscription: true,
      );

  Future<void> _onDriverCancel(
    TrackingDriverCancel event,
    Emitter<TrackingState> emit,
  ) =>
      _onDriverAction(
        TripEvent.cancel,
        event.tripId,
        null,
        emit,
        cancelsSubscription: true,
      );

  Future<void> _onUpdateLocation(
    TrackingUpdateLocation event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await _tripRepository.updateLocation(
      tripId: event.tripId,
      lat: event.latitude,
      lng: event.longitude,
    );

    if (isClosed) return;
    result.fold(
      (failure) => sl<Talker>().warning(
        'TrackingBloc: Failed to update location remotely: ${failure.message}',
      ),
      (_) => null,
    );

    final current = state;
    if (current is TrackingDriverActive) {
      // copyWith is auto-generated by freezed.
      emit(
        current.copyWith(
          currentLocation: Coordinates(
            latitude: event.latitude,
            longitude: event.longitude,
          ),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }
}

/// Internal event: trip was updated via realtime subscription.
class _TripUpdated extends TrackingEvent {
  const _TripUpdated(this.trip);
  final Trip trip;
}

/// Internal event: trip subscription errored.
class _TripUpdateError extends TrackingEvent {
  const _TripUpdateError(this.error);
  final Object error;
}
