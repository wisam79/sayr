import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'tracking_state.freezed.dart';

/// States for the tracking feature.
@freezed
sealed class TrackingState with _$TrackingState {
  const factory TrackingState.initial() = TrackingInitial;

  const factory TrackingState.loading() = TrackingLoading;

  const factory TrackingState.activeTripsLoaded({
    required List<Trip> trips,
    DateTime? lastUpdated,
  }) = TrackingActiveTripsLoaded;

  const factory TrackingState.tripWatching({
    required Trip trip,
    Coordinates? driverLocation,
    DateTime? lastUpdated,
  }) = TrackingTripWatching;

  const factory TrackingState.driverActive({
    required Trip trip,
    required List<TripEvent> validActions,
    Coordinates? currentLocation,
    @Default(false) bool isTrackingLocation,
    DateTime? lastUpdated,
  }) = TrackingDriverActive;

  const factory TrackingState.error({
    required Failure failure,
    TrackingState? previousState,
  }) = TrackingError;
}
