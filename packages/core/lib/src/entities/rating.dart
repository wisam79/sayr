import 'package:equatable/equatable.dart';

import '../value_objects/ids.dart';

/// A rating left by a student for a completed trip.
class Rating extends Equatable {
  const Rating({
    required this.id,
    required this.tripId,
    required this.studentId,
    required this.driverId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  /// Unique rating ID.
  final RatingId id;

  /// The rated trip.
  final TripId tripId;

  /// The student who left the rating.
  final UserId studentId;

  /// The rated driver.
  final DriverId driverId;

  /// Rating value (1-5).
  final int rating;

  /// Optional comment.
  final String? comment;

  /// When the rating was created.
  final DateTime createdAt;

  /// Whether the rating is positive (4 or 5 stars).
  bool get isPositive => rating >= 4;

  /// Whether the rating is negative (1 or 2 stars).
  bool get isNegative => rating <= 2;

  @override
  List<Object?> get props => [
        id,
        tripId,
        studentId,
        driverId,
        rating,
        comment,
        createdAt,
      ];
}
