import 'package:sayr_core/src/utils/string_utils.dart';

/// Trip status - states in the trip state machine.
///
/// The transition rules are defined in TripStateMachine.
enum TripStatus {
  /// Trip is scheduled but not yet started
  scheduled,

  /// Driver has arrived at pickup point
  driverWaiting,

  /// Trip is in progress
  inTransit,

  /// Trip completed normally
  completed,

  /// Driver was absent
  absent,

  /// Trip was cancelled
  cancelled;

  /// Whether this is a terminal state (no further transitions).
  bool get isTerminal {
    return this == TripStatus.completed || this == TripStatus.cancelled;
  }

  /// Whether the trip is active (scheduled, in progress, or about to start).
  bool get isActive {
    return this == TripStatus.scheduled ||
        this == TripStatus.driverWaiting ||
        this == TripStatus.inTransit;
  }

  /// Parse from database string value.
  static TripStatus fromString(String value) {
    // Database uses snake_case
    final normalized = value.toCamelCase();
    return TripStatus.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => throw ArgumentError('Unknown TripStatus: $value'),
    );
  }
}
