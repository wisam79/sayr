import 'package:fsm2/fsm2.dart';
import 'package:sayr_core/src/enums/trip_status.dart';
import 'package:sayr_core/src/fsm/trip_event.dart';

// States
class Scheduled extends State {}

class DriverWaiting extends State {}

class InTransit extends State {}

class Completed extends State {}

class Absent extends State {}

class Cancelled extends State {}

// Events
class ArriveEvent extends Event {}

class StartEvent extends Event {}

class CompleteEvent extends Event {}

class MarkAbsentEvent extends Event {}

class CancelEvent extends Event {}

/// Finite State Machine for Trip status transitions.
///
/// Validates that a [TripStatus] → [TripEvent] → [TripStatus] transition
/// is allowed before applying it using the `fsm2` package.
class TripStateMachine {
  const TripStateMachine._();

  static final _graph = () {
    final builder = GraphBuilder()
      ..initialState<Scheduled>()
      ..state<Scheduled>(
        (g) => g
          ..on<ArriveEvent, DriverWaiting>()
          ..on<MarkAbsentEvent, Absent>()
          ..on<CancelEvent, Cancelled>(),
      )
      ..state<DriverWaiting>(
        (g) => g
          ..on<StartEvent, InTransit>()
          ..on<MarkAbsentEvent, Absent>()
          ..on<CancelEvent, Cancelled>(),
      )
      ..state<InTransit>(
        (g) => g
          ..on<CompleteEvent, Completed>()
          ..on<CancelEvent, Cancelled>(),
      )
      ..state<Absent>(
        (g) => g..on<CancelEvent, Cancelled>(),
      )
      ..state<Completed>((g) => g)
      ..state<Cancelled>((g) => g);
    return builder.build();
  }();

  static Type _statusToState(TripStatus status) {
    return switch (status) {
      TripStatus.scheduled => Scheduled,
      TripStatus.driverWaiting => DriverWaiting,
      TripStatus.inTransit => InTransit,
      TripStatus.completed => Completed,
      TripStatus.absent => Absent,
      TripStatus.cancelled => Cancelled,
    };
  }

  static TripStatus _stateToStatus(Type stateType) {
    if (stateType == Scheduled) return TripStatus.scheduled;
    if (stateType == DriverWaiting) return TripStatus.driverWaiting;
    if (stateType == InTransit) return TripStatus.inTransit;
    if (stateType == Completed) return TripStatus.completed;
    if (stateType == Absent) return TripStatus.absent;
    if (stateType == Cancelled) return TripStatus.cancelled;
    throw ArgumentError('Unknown state type: $stateType');
  }

  static Type _eventToFsmEventType(TripEvent event) {
    if (event == TripEvent.arrive) return ArriveEvent;
    if (event == TripEvent.start) return StartEvent;
    if (event == TripEvent.complete) return CompleteEvent;
    if (event == TripEvent.markAbsent) return MarkAbsentEvent;
    if (event == TripEvent.cancel) return CancelEvent;
    throw ArgumentError('Unknown event: $event');
  }

  static TripEvent _fsmEventTypeToEvent(Type eventType) {
    if (eventType == ArriveEvent) return TripEvent.arrive;
    if (eventType == StartEvent) return TripEvent.start;
    if (eventType == CompleteEvent) return TripEvent.complete;
    if (eventType == MarkAbsentEvent) return TripEvent.markAbsent;
    if (eventType == CancelEvent) return TripEvent.cancel;
    throw ArgumentError('Unknown event type: $eventType');
  }

  /// Returns the next [TripStatus] for a given [from] state and [event],
  /// or `null` if the transition is not allowed.
  static TripStatus? transition(TripStatus from, TripEvent event) {
    final fromType = _statusToState(from);
    final eventType = _eventToFsmEventType(event);

    final stateDef = _graph.findStateDefinition(fromType);
    if (stateDef == null) return null;

    final transitions = stateDef.getTransitions();
    for (final transition in transitions) {
      if (transition.triggerEvents.contains(eventType)) {
        if (transition.targetStates.isNotEmpty) {
          return _stateToStatus(transition.targetStates.first);
        }
      }
    }
    return null;
  }

  /// Returns `true` if the transition is valid.
  static bool canTransition(TripStatus from, TripEvent event) {
    return transition(from, event) != null;
  }

  /// Returns `true` if the state is terminal (no further transitions).
  ///
  /// Note: [TripStatus.absent] is a semi-terminal state that can only transition to [TripStatus.cancelled].
  static bool isTerminal(TripStatus state) {
    return state == TripStatus.completed || state == TripStatus.cancelled;
  }

  /// Returns all valid events from a given state.
  static List<TripEvent> validEventsFrom(TripStatus state) {
    final fromType = _statusToState(state);
    final stateDef = _graph.findStateDefinition(fromType);
    if (stateDef == null) return const [];

    final list = <TripEvent>[];
    final transitions = stateDef.getTransitions();
    for (final transition in transitions) {
      for (final triggerEvent in transition.triggerEvents) {
        final tripEvent = _fsmEventTypeToEvent(triggerEvent);
        if (!list.contains(tripEvent)) {
          list.add(tripEvent);
        }
      }
    }
    return list;
  }

  /// Returns all valid next states from a given state.
  static List<TripStatus> validNextStates(TripStatus state) {
    final fromType = _statusToState(state);
    final stateDef = _graph.findStateDefinition(fromType);
    if (stateDef == null) return const [];

    final list = <TripStatus>[];
    final transitions = stateDef.getTransitions();
    for (final transition in transitions) {
      for (final targetState in transition.targetStates) {
        final tripStatus = _stateToStatus(targetState);
        if (!list.contains(tripStatus)) {
          list.add(tripStatus);
        }
      }
    }
    return list;
  }
}
