part of 'emergency_bloc.dart';

/// Base class for all emergency events.
sealed class EmergencyEvent extends Equatable {
  /// Constructor for [EmergencyEvent].
  const EmergencyEvent();

  @override
  List<Object?> get props => [];
}

/// User pressed the SOS button.
class EmergencyTriggered extends EmergencyEvent {
  /// Creates an [EmergencyTriggered] event.
  const EmergencyTriggered({
    required this.tripId,
    required this.routeId,
    this.location,
    this.message,
  });

  /// The active trip ID.
  final TripId tripId;

  /// The active route ID.
  final RouteId routeId;

  /// Current GPS coordinates.
  final Coordinates? location;

  /// Optional detail message.
  final String? message;

  @override
  List<Object?> get props => [tripId, routeId, location, message];
}

/// User wants to cancel/resolve an active report.
class EmergencyCancelled extends EmergencyEvent {
  /// Creates an [EmergencyCancelled] event.
  const EmergencyCancelled();
}

/// Reset to idle (e.g. when leaving the trip page).
class EmergencyReset extends EmergencyEvent {
  /// Creates an [EmergencyReset] event.
  const EmergencyReset();
}
