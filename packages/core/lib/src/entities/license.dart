import 'package:equatable/equatable.dart';

import '../enums/license_status.dart';
import '../value_objects/ids.dart';
import '../value_objects/license_code.dart';

/// A license code that grants a student access to a route.
class License extends Equatable {
  const License({
    required this.id,
    required this.batchId,
    required this.routeId,
    required this.code,
    required this.status,
    required this.validDays,
    required this.createdAt,
    this.usedBy,
    this.usedAt,
  });

  /// Unique license ID.
  final LicenseId id;

  /// The batch this license belongs to.
  final LicenseBatchId batchId;

  /// The route this license grants access to.
  final RouteId routeId;

  /// The 8-character license code.
  final LicenseCode code;

  /// Current status.
  final LicenseStatus status;

  /// Number of days the subscription will be valid.
  final int validDays;

  /// When the license was created.
  final DateTime createdAt;

  /// User who activated this license (if used).
  final UserId? usedBy;

  /// When the license was used.
  final DateTime? usedAt;

  /// Whether this license can be activated.
  bool get isActivatable => status.isActivatable;

  @override
  List<Object?> get props => [
        id,
        batchId,
        routeId,
        code,
        status,
        validDays,
        createdAt,
        usedBy,
        usedAt,
      ];
}

/// A batch of licenses created by an admin.
class LicenseBatch extends Equatable {
  const LicenseBatch({
    required this.id,
    required this.createdBy,
    required this.routeId,
    required this.batchName,
    required this.quantity,
    required this.price,
    required this.validDays,
    required this.createdAt,
  });

  /// Unique batch ID.
  final LicenseBatchId id;

  /// Admin who created the batch.
  final UserId createdBy;

  /// The route for these licenses.
  final RouteId routeId;

  /// Display name for the batch.
  final String batchName;

  /// Number of licenses in the batch.
  final int quantity;

  /// Price per license.
  final int price;

  /// Validity period in days.
  final int validDays;

  /// When the batch was created.
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        createdBy,
        routeId,
        batchName,
        quantity,
        price,
        validDays,
        createdAt,
      ];
}
