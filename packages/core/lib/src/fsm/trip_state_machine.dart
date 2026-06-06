import 'package:sayr_core/src/enums/trip_status.dart';
import 'package:sayr_core/src/fsm/trip_event.dart';

/// Finite State Machine for Trip status transitions.
///
/// Validates that a [TripStatus] → [TripEvent] → [TripStatus] transition
/// is allowed before applying it.
///
/// ## Transition Matrix
///
/// | From            | Event         | To              |
/// |-----------------|---------------|-----------------|
/// | scheduled       | arrive        | driverWaiting   |
/// | scheduled       | markAbsent    | absent          |
/// | scheduled       | cancel        | cancelled       |
/// | driverWaiting   | start         | inTransit       |
/// | driverWaiting   | markAbsent    | absent          |
/// | driverWaiting   | cancel        | cancelled       |
/// | inTransit       | complete      | completed       |
/// | inTransit       | cancel        | cancelled       |
/// | absent          | cancel        | cancelled       |
/// | completed       | (terminal)    | -               |
/// | cancelled       | (terminal)    | -               |
class TripStateMachine {
  const TripStateMachine._();

  /// Internal transition map.
  static const Map<TripStatus, Map<String, TripStatus>> _transitions = {
    TripStatus.scheduled: {
      'arrive': TripStatus.driverWaiting,
      'markAbsent': TripStatus.absent,
      'cancel': TripStatus.cancelled,
    },
    TripStatus.driverWaiting: {
      'start': TripStatus.inTransit,
      'markAbsent': TripStatus.absent,
      'cancel': TripStatus.cancelled,
    },
    TripStatus.inTransit: {
      'complete': TripStatus.completed,
      'cancel': TripStatus.cancelled,
    },
    TripStatus.absent: {
      'cancel': TripStatus.cancelled,
    },
    TripStatus.completed: {},
    TripStatus.cancelled: {},
  };

  /// Returns the next [TripStatus] for a given [from] state and [event],
  /// or `null` if the transition is not allowed.
  static TripStatus? transition(TripStatus from, TripEvent event) {
    return _transitions[from]?[event.name];
  }

  /// Returns `true` if the transition is valid.
  static bool canTransition(TripStatus from, TripEvent event) {
    return _transitions[from]?.containsKey(event.name) ?? false;
  }

  /// Returns `true` if the state is terminal (no further transitions).
  static bool isTerminal(TripStatus state) {
    return _transitions[state]?.isEmpty ?? true;
  }

  /// Returns all valid events from a given state.
  static List<TripEvent> validEventsFrom(TripStatus state) {
    final events = _transitions[state]?.keys.toList() ?? <String>[];
    return events.map(_eventFromName).whereType<TripEvent>().toList();
  }

  /// Returns all valid next states from a given state.
  static List<TripStatus> validNextStates(TripStatus state) {
    return _transitions[state]?.values.toList() ?? <TripStatus>[];
  }

  static TripEvent? _eventFromName(String name) {
    switch (name) {
      case 'arrive':
        return TripEvent.arrive;
      case 'start':
        return TripEvent.start;
      case 'complete':
        return TripEvent.complete;
      case 'markAbsent':
        return TripEvent.markAbsent;
      case 'cancel':
        return TripEvent.cancel;
      default:
        return null;
    }
  }
}
