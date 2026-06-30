import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'rating.freezed.dart';

/// A rating left by a student for a completed trip.
@freezed
abstract class Rating with _$Rating {
  const factory Rating({
    required RatingId id,
    required TripId tripId,
    required UserId studentId,
    required DriverId driverId,
    required int rating,
    required DateTime createdAt,
    String? comment,
  }) = _Rating;

  const Rating._();

  /// Whether the rating is positive (4 or 5 stars).
  bool get isPositive => rating >= 4;

  /// Whether the rating is negative (1 or 2 stars).
  bool get isNegative => rating <= 2;
}
