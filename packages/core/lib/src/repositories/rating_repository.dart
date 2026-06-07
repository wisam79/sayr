import 'package:fpdart/fpdart.dart';

import 'package:sayr_core/src/entities/rating.dart';
import 'package:sayr_core/src/failures/failure.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

/// Interface for rating operations repository.
abstract class RatingRepository {
  /// Submit a student rating for a trip.
  Future<Either<Failure, Rating>> submitRating({
    required TripId tripId,
    required DriverId driverId,
    required int rating,
    String? comment,
  });

  /// Get an existing rating for a trip.
  Future<Either<Failure, Rating?>> getTripRating(TripId tripId);
}
