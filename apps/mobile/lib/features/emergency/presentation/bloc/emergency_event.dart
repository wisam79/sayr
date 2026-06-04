part of 'emergency_bloc.dart';

sealed class EmergencyEvent extends Equatable {
  const EmergencyEvent();

  @override
  List<Object?> get props => [];
}

/// User pressed the SOS button.
class EmergencyTriggered extends EmergencyEvent {
  const EmergencyTriggered({
    required this.tripId,
    required this.routeId,
    required this.location,
    this.message,
  });

  final TripId tripId;
  final RouteId routeId;
  final Coordinates location;
  final String? message;

  @override
  List<Object?> get props => [tripId, routeId, location, message];
}

/// User wants to cancel/resolve an active report.
class EmergencyCancelled extends EmergencyEvent {
  const EmergencyCancelled();
}

/// Reset to idle (e.g. when leaving the trip page).
class EmergencyReset extends EmergencyEvent {
  const EmergencyReset();
}
