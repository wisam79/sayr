import '../utils/string_utils.dart';

/// Trip status - states in the trip state machine.
///
/// The transition rules are defined in [TripStateMachine].
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

  /// Display name in Arabic.
  String get displayNameAr {
    switch (this) {
      case TripStatus.scheduled:
        return 'مجدولة';
      case TripStatus.driverWaiting:
        return 'السائق في الانتظار';
      case TripStatus.inTransit:
        return 'قيد السير';
      case TripStatus.completed:
        return 'مكتملة';
      case TripStatus.absent:
        return 'غياب';
      case TripStatus.cancelled:
        return 'ملغاة';
    }
  }

  /// Whether this is a terminal state (no further transitions).
  bool get isTerminal {
    return this == TripStatus.completed || this == TripStatus.cancelled;
  }

  /// Whether the trip is active (in progress or about to start).
  bool get isActive {
    return this == TripStatus.driverWaiting || this == TripStatus.inTransit;
  }

  /// Parse from database string value.
  static TripStatus fromString(String value) {
    // Database uses snake_case
    final normalized = value.toCamelCase();
    return TripStatus.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => TripStatus.scheduled,
    );
  }
}
