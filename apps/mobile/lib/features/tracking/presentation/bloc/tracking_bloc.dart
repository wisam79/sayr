import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';
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
    required LocationService driverLocationService,
    required Talker talker,
  })  : _tripRepository = tripRepository,
        _authRepository = authRepository,
        _driverLocationService = driverLocationService,
        _talker = talker,
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
  final LocationService _driverLocationService;
  final Talker _talker;
  StreamSubscription<Trip>? _tripSubscription;
  StreamSubscription<Either<Failure, Coordinates>>? _locationSubscription;

  @override
  Future<void> close() async {
    if (_tripSubscription != null) {
      await _tripSubscription!.cancel();
    }
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
    }
    // Release the GPS stream so the foreground service stops when the bloc
    // (and therefore the tracking session) is torn down.
    await _driverLocationService.stopTracking();
    await super.close();
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
      (data) => emit(
        TrackingState.activeTripsLoaded(
          trips: data.trips,
          fromCache: data.fromCache,
        ),
      ),
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
    final sub = _tripSubscription;
    if (sub != null) {
      await sub.cancel();
    }

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

    final stream = _tripRepository.watchTrip(event.tripId);

    _tripSubscription = stream.listen(
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
    bool? isTrackingLocation,
  }) {
    final actions = TripStateMachine.validEventsFrom(trip.status);
    emit(
      TrackingState.driverActive(
        trip: trip,
        validActions: actions,
        currentLocation: currentLocation,
        isTrackingLocation:
            isTrackingLocation ?? (_driverLocationService.isTracking == true),
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
    String? notificationTitle,
    String? notificationText,
  }) async {
    if (activatesTracking) {
      final trackResult = await _driverLocationService.startTracking(
        tripId,
        notificationTitle: notificationTitle ?? '',
        notificationText: notificationText ?? '',
      );
      final trackSuccess = await trackResult.fold(
        (failure) async {
          emit(
            TrackingState.error(
              failure: failure,
              previousState: state,
            ),
          );
          return false;
        },
        (_) async => true,
      );
      if (!trackSuccess) return;
    }

    final result = await _tripRepository.updateStatus(
      tripId: tripId,
      event: action,
      location: location,
    );

    if (isClosed) {
      if (activatesTracking) {
        unawaited(_driverLocationService.stopTracking());
      }
      return;
    }

    await result.fold(
      (failure) async {
        if (activatesTracking) {
          await _driverLocationService.stopTracking();
        }
        emit(
          TrackingState.error(
            failure: failure,
            previousState: state,
          ),
        );
      },
      (trip) async {
        if (cancelsSubscription) {
          unawaited(_tripSubscription?.cancel());
          unawaited(_locationSubscription?.cancel());
          _locationSubscription = null;
          // Trip is over — stop streaming the driver's location.
          await _driverLocationService.stopTracking();
        }
        var actualTrackingActive = false;
        if (activatesTracking) {
          _startLocationSubscription();
          actualTrackingActive = true;
        }
        final actions = TripStateMachine.validEventsFrom(trip.status);
        emit(
          TrackingState.driverActive(
            trip: trip,
            validActions: actions,
            currentLocation: location ?? trip.lastLocation,
            isTrackingLocation: activatesTracking
                ? actualTrackingActive
                : (_driverLocationService.isTracking == true),
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  void _startLocationSubscription() {
    _locationSubscription?.cancel();
    _locationSubscription = _driverLocationService.locationStream.listen(
      (result) {
        result.fold(
          (failure) {
            _talker.warning(
              'TrackingBloc: location stream failure: $failure',
            );
          },
          (coordinates) {
            final current = state;
            if (current is TrackingDriverActive) {
              add(
                TrackingUpdateLocation(
                  tripId: current.trip.id,
                  latitude: coordinates.latitude,
                  longitude: coordinates.longitude,
                ),
              );
            }
          },
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
        notificationTitle: event.notificationTitle,
        notificationText: event.notificationText,
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
        event.location,
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
      (failure) => _talker.warning(
        'TrackingBloc: Failed to update location remotely: ${failure.message}',
      ),
      (_) {
        final current = state;
        if (current is TrackingDriverActive) {
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
      },
    );
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
