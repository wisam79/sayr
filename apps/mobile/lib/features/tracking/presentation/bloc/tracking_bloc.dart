import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:sayr_core/sayr_core.dart';

import 'tracking_event.dart';
import 'tracking_state.dart';

/// BLoC for trip tracking — student view and driver controls.
///
/// Student: loads active trips on map, watches a specific trip.
/// Driver: manages trip lifecycle (arrive/start/complete/cancel) and streams location.
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc({
    required TripRepository tripRepository,
  })  : _tripRepository = tripRepository,
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
  StreamSubscription<Trip>? _tripSubscription;

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadActiveTrips(
    TrackingLoadActiveTrips event,
    Emitter<TrackingState> emit,
  ) async {
    emit(const TrackingState.loading());
    final result = await _tripRepository.getActiveTrips();
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
    result.fold(
      (failure) => emit(TrackingState.error(failure: failure)),
      (trip) {
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(TrackingState.driverActive(
          trip: trip,
          validActions: actions,
          lastUpdated: DateTime.now(),
        ));
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
      final trip = current.trips.cast<Trip?>().firstWhere(
            (t) => t!.id == event.tripId,
            orElse: () => null,
          );
      if (trip != null) {
        emit(TrackingState.tripWatching(
          trip: trip,
          driverLocation: trip.lastLocation,
        ));
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
    _tripSubscription?.cancel();
    _tripSubscription = null;
  }

  void _onTripUpdated(_TripUpdated event, Emitter<TrackingState> emit) {
    final current = state;
    if (current is TrackingTripWatching && event.trip.id == current.trip.id) {
      emit(TrackingState.tripWatching(
        trip: event.trip,
        driverLocation: event.trip.lastLocation,
        lastUpdated: DateTime.now(),
      ));
    } else if (current is TrackingDriverActive &&
        event.trip.id == current.trip.id) {
      final actions = TripStateMachine.validEventsFrom(event.trip.status);
      emit(TrackingState.driverActive(
        trip: event.trip,
        validActions: actions,
        currentLocation: current.currentLocation,
        isTrackingLocation: current.isTrackingLocation,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  void _onTripUpdateError(
    _TripUpdateError event,
    Emitter<TrackingState> emit,
  ) {
    emit(TrackingState.error(
      failure: UnknownFailure(message: event.error.toString()),
      previousState: state,
    ));
  }

  Future<void> _onDriverArrive(
    TrackingDriverArrive event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await _tripRepository.updateStatus(
      tripId: event.tripId,
      event: TripEvent.arrive,
      location: event.location,
    );
    result.fold(
      (failure) => emit(TrackingState.error(
        failure: failure,
        previousState: state,
      )),
      (trip) {
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(TrackingState.driverActive(
          trip: trip,
          validActions: actions,
          currentLocation: event.location,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onDriverStart(
    TrackingDriverStart event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await _tripRepository.updateStatus(
      tripId: event.tripId,
      event: TripEvent.start,
      location: event.location,
    );
    result.fold(
      (failure) => emit(TrackingState.error(
        failure: failure,
        previousState: state,
      )),
      (trip) {
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(TrackingState.driverActive(
          trip: trip,
          validActions: actions,
          currentLocation: event.location,
          isTrackingLocation: true,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onDriverComplete(
    TrackingDriverComplete event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await _tripRepository.updateStatus(
      tripId: event.tripId,
      event: TripEvent.complete,
      location: event.location,
    );
    result.fold(
      (failure) => emit(TrackingState.error(
        failure: failure,
        previousState: state,
      )),
      (trip) {
        _tripSubscription?.cancel();
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(TrackingState.driverActive(
          trip: trip,
          validActions: actions,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onDriverMarkAbsent(
    TrackingDriverMarkAbsent event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await _tripRepository.updateStatus(
      tripId: event.tripId,
      event: TripEvent.markAbsent,
    );
    result.fold(
      (failure) => emit(TrackingState.error(
        failure: failure,
        previousState: state,
      )),
      (trip) {
        _tripSubscription?.cancel();
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(TrackingState.driverActive(
          trip: trip,
          validActions: actions,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onDriverCancel(
    TrackingDriverCancel event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await _tripRepository.updateStatus(
      tripId: event.tripId,
      event: TripEvent.cancel,
    );
    result.fold(
      (failure) => emit(TrackingState.error(
        failure: failure,
        previousState: state,
      )),
      (trip) {
        _tripSubscription?.cancel();
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(TrackingState.driverActive(
          trip: trip,
          validActions: actions,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onUpdateLocation(
    TrackingUpdateLocation event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await _tripRepository.updateLocation(
      tripId: event.tripId,
      lat: event.latitude,
      lng: event.longitude,
    );

    result.fold(
      (failure) => debugPrint(
          'TrackingBloc: Failed to update location remotely: ${failure.message}'),
      (_) => null,
    );

    final current = state;
    if (current is TrackingDriverActive) {
      // copyWith is auto-generated by freezed.
      emit(current.copyWith(
        currentLocation: Coordinates(
          latitude: event.latitude,
          longitude: event.longitude,
        ),
        lastUpdated: DateTime.now(),
      ));
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
