import 'package:equatable/equatable.dart';

/// Strongly-typed IDs to prevent mixing them up.
///
/// Each ID is a wrapper around a String UUID, but the type system
/// prevents passing a `UserId` where a `RouteId` is expected.
sealed class Id extends Equatable {
  const Id(this.value);

  /// The raw UUID value.
  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => '$runtimeType($value)';
}

/// A user ID.
class UserId extends Id {
  const UserId(super.value);
}

/// A route ID.
class RouteId extends Id {
  const RouteId(super.value);
}

/// A trip ID.
class TripId extends Id {
  const TripId(super.value);
}

/// A subscription ID.
class SubscriptionId extends Id {
  const SubscriptionId(super.value);
}

/// A license ID.
class LicenseId extends Id {
  const LicenseId(super.value);
}

/// A license batch ID.
class LicenseBatchId extends Id {
  const LicenseBatchId(super.value);
}

/// A driver ID.
class DriverId extends Id {
  const DriverId(super.value);
}

/// An institution ID.
class InstitutionId extends Id {
  const InstitutionId(super.value);
}

/// A payout ID.
class PayoutId extends Id {
  const PayoutId(super.value);
}

/// A rating ID.
class RatingId extends Id {
  const RatingId(super.value);
}

/// A conversation ID.
class ConversationId extends Id {
  const ConversationId(super.value);
}

/// A message ID.
class MessageId extends Id {
  const MessageId(super.value);
}

/// A notification ID.
class NotificationId extends Id {
  const NotificationId(super.value);
}

/// An emergency report ID.
class EmergencyReportId extends Id {
  const EmergencyReportId(super.value);
}

/// A boarding record ID.
class BoardingId extends Id {
  const BoardingId(super.value);
}

/// A boarding token ID.
class BoardingTokenId extends Id {
  const BoardingTokenId(super.value);
}
