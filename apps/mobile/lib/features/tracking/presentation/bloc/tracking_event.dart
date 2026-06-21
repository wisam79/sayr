import 'package:sayr_core/sayr_core.dart';

/// Base class for tracking events.
abstract class TrackingEvent {
  /// Constructor for [TrackingEvent].
  const TrackingEvent();
}

/// Load all active trips for the current user.
class TrackingLoadActiveTrips extends TrackingEvent {
  /// Creates a [TrackingLoadActiveTrips] event.
  const TrackingLoadActiveTrips();
}

/// Start watching a specific trip's live location.
class TrackingWatchTrip extends TrackingEvent {
  /// Creates a [TrackingWatchTrip] event.
  const TrackingWatchTrip({required this.tripId});

  /// The ID of the trip to watch.
  final TripId tripId;
}

/// Stop watching the current trip.
class TrackingStopWatching extends TrackingEvent {
  /// Creates a [TrackingStopWatching] event.
  const TrackingStopWatching();
}

/// Driver: Start a trip (transition scheduled -> driverWaiting).
class TrackingDriverArrive extends TrackingEvent {
  /// Creates a [TrackingDriverArrive] event.
  const TrackingDriverArrive({required this.tripId, this.location});

  /// The ID of the trip.
  final TripId tripId;

  /// Optional coordinates when driver arrived.
  final Coordinates? location;
}

/// Driver: Begin the trip (transition driverWaiting -> inTransit).
class TrackingDriverStart extends TrackingEvent {
  /// Creates a [TrackingDriverStart] event.
  const TrackingDriverStart({
    required this.tripId,
    required this.notificationTitle,
    required this.notificationText,
    this.location,
  });

  /// The ID of the trip.
  final TripId tripId;

  /// Optional coordinates when driver started the trip.
  final Coordinates? location;

  /// Localized title for background notification.
  final String notificationTitle;

  /// Localized text/body for background notification.
  final String notificationText;
}

/// Driver: Complete the trip (transition inTransit -> completed).
class TrackingDriverComplete extends TrackingEvent {
  /// Creates a [TrackingDriverComplete] event.
  const TrackingDriverComplete({required this.tripId, this.location});

  /// The ID of the trip.
  final TripId tripId;

  /// Optional coordinates when trip was completed.
  final Coordinates? location;
}

/// Driver: Mark trip as absent.
class TrackingDriverMarkAbsent extends TrackingEvent {
  /// Creates a [TrackingDriverMarkAbsent] event.
  const TrackingDriverMarkAbsent({
    required this.tripId,
    required this.location,
  });

  /// The ID of the trip.
  final TripId tripId;

  /// Current location when marking absent.
  final Coordinates location;
}

/// Driver: Cancel the trip.
class TrackingDriverCancel extends TrackingEvent {
  /// Creates a [TrackingDriverCancel] event.
  const TrackingDriverCancel({required this.tripId});

  /// The ID of the trip.
  final TripId tripId;
}

/// Driver: Update vehicle location (no status change).
class TrackingUpdateLocation extends TrackingEvent {
  /// Creates a [TrackingUpdateLocation] event.
  const TrackingUpdateLocation({
    required this.tripId,
    required this.latitude,
    required this.longitude,
  });

  /// The ID of the trip.
  final TripId tripId;

  /// Current latitude coordinate.
  final double latitude;

  /// Current longitude coordinate.
  final double longitude;
}

/// Driver: Create a new trip for a route.
class TrackingCreateTrip extends TrackingEvent {
  /// Creates a [TrackingCreateTrip] event.
  const TrackingCreateTrip({required this.routeId, required this.scheduledAt});

  /// The ID of the route.
  final RouteId routeId;

  /// Time when the trip is scheduled to start.
  final DateTime scheduledAt;
}
