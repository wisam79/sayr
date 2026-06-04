import 'package:equatable/equatable.dart';

import '../enums/payout_status.dart';
import '../value_objects/ids.dart';
import '../value_objects/money.dart';

/// A driver's payout request.
class Payout extends Equatable {
  const Payout({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.referenceNote,
  });

  /// Unique payout ID.
  final PayoutId id;

  /// The driver requesting the payout.
  final DriverId driverId;

  /// Amount to be paid.
  final Money amount;

  /// Current status.
  final PayoutStatus status;

  /// Reference note from admin.
  final String? referenceNote;

  /// When the payout was requested.
  final DateTime createdAt;

  /// When the status was last changed.
  final DateTime updatedAt;

  /// Whether the payout is awaiting review.
  bool get isPending => status.isPending;

  @override
  List<Object?> get props => [
        id,
        driverId,
        amount,
        status,
        referenceNote,
        createdAt,
        updatedAt,
      ];
}
