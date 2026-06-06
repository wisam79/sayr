import 'package:sayr_core/sayr_core.dart' show TripStateMachine;
import 'package:sayr_core/src/fsm/trip_state_machine.dart'
    show TripStateMachine;

/// Trip state machine events.
///
/// Events trigger state transitions. The transition rules
/// are defined in [TripStateMachine].
class TripEvent {
  const TripEvent._(this.name);

  /// Name of the event (matches key in the transition map)
  final String name;

  /// Driver arrived at pickup point
  static const arrive = TripEvent._('arrive');

  /// Driver started the trip
  static const start = TripEvent._('start');

  /// Trip completed normally
  static const complete = TripEvent._('complete');

  /// Driver was marked absent
  static const markAbsent = TripEvent._('markAbsent');

  /// Trip was cancelled
  static const cancel = TripEvent._('cancel');

  @override
  String toString() => 'TripEvent.$name';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TripEvent && other.name == name);

  @override
  int get hashCode => name.hashCode;
}
