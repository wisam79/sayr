import 'package:fpdart/fpdart.dart';

import 'package:sayr_core/src/entities/driver.dart';
import 'package:sayr_core/src/entities/user.dart';
import 'package:sayr_core/src/failures/failure.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

/// Interface for driver operations repository.
abstract class DriverRepository {
  /// Fetch driver details.
  Future<Either<Failure, Driver>> getDriverById(DriverId id);

  /// Fetch user profile (to load name/avatar/phone for contact).
  Future<Either<Failure, User>> getDriverProfile(UserId userId);
}
