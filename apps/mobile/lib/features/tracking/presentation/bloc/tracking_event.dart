import 'package:sayr_core/sayr_core.dart';

/// Base class for tracking events.
abstract class TrackingEvent {
  const TrackingEvent();
}

/// Load all active trips for the current user.
class TrackingLoadActiveTrips extends TrackingEvent {
  const TrackingLoadActiveTrips();
}

/// Start watching a specific trip's live location.
class TrackingWatchTrip extends TrackingEvent {
  const TrackingWatchTrip({required this.tripId});
  final TripId tripId;
}

/// Stop watching the current trip.
class TrackingStopWatching extends TrackingEvent {
  const TrackingStopWatching();
}

/// Driver: Start a trip (transition scheduled -> driverWaiting).
class TrackingDriverArrive extends TrackingEvent {
  const TrackingDriverArrive({required this.tripId, this.location});
  final TripId tripId;
  final Coordinates? location;
}

/// Driver: Begin the trip (transition driverWaiting -> inTransit).
class TrackingDriverStart extends TrackingEvent {
  const TrackingDriverStart({required this.tripId, this.location});
  final TripId tripId;
  final Coordinates? location;
}

/// Driver: Complete the trip (transition inTransit -> completed).
class TrackingDriverComplete extends TrackingEvent {
  const TrackingDriverComplete({required this.tripId, this.location});
  final TripId tripId;
  final Coordinates? location;
}

/// Driver: Mark trip as absent.
class TrackingDriverMarkAbsent extends TrackingEvent {
  const TrackingDriverMarkAbsent({required this.tripId});
  final TripId tripId;
}

/// Driver: Cancel the trip.
class TrackingDriverCancel extends TrackingEvent {
  const TrackingDriverCancel({required this.tripId});
  final TripId tripId;
}

/// Driver: Update vehicle location (no status change).
class TrackingUpdateLocation extends TrackingEvent {
  const TrackingUpdateLocation({
    required this.tripId,
    required this.latitude,
    required this.longitude,
  });
  final TripId tripId;
  final double latitude;
  final double longitude;
}

/// Driver: Create a new trip for a route.
class TrackingCreateTrip extends TrackingEvent {
  const TrackingCreateTrip({required this.routeId, required this.scheduledAt});
  final RouteId routeId;
  final DateTime scheduledAt;
}
