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

  /// Returns the next [TripStatus] for a given [from] state and [event],
  /// or `null` if the transition is not allowed.
  static TripStatus? transition(TripStatus from, TripEvent event) {
    return switch ((from, event)) {
      (TripStatus.scheduled, TripEvent.arrive) => TripStatus.driverWaiting,
      (TripStatus.scheduled, TripEvent.markAbsent) => TripStatus.absent,
      (TripStatus.scheduled, TripEvent.cancel) => TripStatus.cancelled,
      (TripStatus.driverWaiting, TripEvent.start) => TripStatus.inTransit,
      (TripStatus.driverWaiting, TripEvent.markAbsent) => TripStatus.absent,
      (TripStatus.driverWaiting, TripEvent.cancel) => TripStatus.cancelled,
      (TripStatus.inTransit, TripEvent.complete) => TripStatus.completed,
      (TripStatus.inTransit, TripEvent.cancel) => TripStatus.cancelled,
      (TripStatus.absent, TripEvent.cancel) => TripStatus.cancelled,
      _ => null,
    };
  }

  /// Returns `true` if the transition is valid.
  static bool canTransition(TripStatus from, TripEvent event) {
    return transition(from, event) != null;
  }

  /// Returns `true` if the state is terminal (no further transitions).
  static bool isTerminal(TripStatus state) {
    return switch (state) {
      TripStatus.completed || TripStatus.cancelled => true,
      _ => false,
    };
  }

  /// Returns all valid events from a given state.
  static List<TripEvent> validEventsFrom(TripStatus state) {
    return switch (state) {
      TripStatus.scheduled => const [
          TripEvent.arrive,
          TripEvent.markAbsent,
          TripEvent.cancel,
        ],
      TripStatus.driverWaiting => const [
          TripEvent.start,
          TripEvent.markAbsent,
          TripEvent.cancel,
        ],
      TripStatus.inTransit => const [TripEvent.complete, TripEvent.cancel],
      TripStatus.absent => const [TripEvent.cancel],
      TripStatus.completed || TripStatus.cancelled => const [],
    };
  }

  /// Returns all valid next states from a given state.
  static List<TripStatus> validNextStates(TripStatus state) {
    return switch (state) {
      TripStatus.scheduled => const [
          TripStatus.driverWaiting,
          TripStatus.absent,
          TripStatus.cancelled,
        ],
      TripStatus.driverWaiting => const [
          TripStatus.inTransit,
          TripStatus.absent,
          TripStatus.cancelled,
        ],
      TripStatus.inTransit => const [
          TripStatus.completed,
          TripStatus.cancelled,
        ],
      TripStatus.absent => const [TripStatus.cancelled],
      TripStatus.completed || TripStatus.cancelled => const [],
    };
  }
}
