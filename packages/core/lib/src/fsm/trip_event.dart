/// Trip state machine events.
///
/// Events trigger state transitions.
enum TripEvent {
  /// Driver arrived at pickup point
  arrive,

  /// Driver started the trip
  start,

  /// Trip completed normally
  complete,

  /// Driver was marked absent
  markAbsent,

  /// Trip was cancelled
  cancel;

  @override
  String toString() => 'TripEvent.$name';
}
