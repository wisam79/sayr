import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/ids.dart';
import '../utils/json_converters.dart';

part 'rating.freezed.dart';
part 'rating.g.dart';

/// A rating left by a student for a completed trip.
@freezed
abstract class Rating with _$Rating {
  const factory Rating({
    @JsonKey(fromJson: ratingIdFromJson, toJson: ratingIdToJson)
    required RatingId id,
    @JsonKey(fromJson: tripIdFromJson, toJson: tripIdToJson)
    required TripId tripId,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId studentId,
    @JsonKey(fromJson: driverIdFromJson, toJson: driverIdToJson)
    required DriverId driverId,
    required int rating,
    required DateTime createdAt,
    String? comment,
  }) = _Rating;

  const Rating._();

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);

  /// Whether the rating is positive (4 or 5 stars).
  bool get isPositive => rating >= 4;

  /// Whether the rating is negative (1 or 2 stars).
  bool get isNegative => rating <= 2;
}
