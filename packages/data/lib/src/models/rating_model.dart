import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'rating_model.freezed.dart';
part 'rating_model.g.dart';

/// DTO for Rating rows coming from Supabase.
///
/// Mirrors the column names of the `ratings` table so the raw RPC/select row
/// can be parsed directly via [RatingModel.fromJson], then converted to the
/// [Rating] domain entity via [toEntity]. This replaces the hand-written
/// `_ratingFromDb` mapper that previously lived in the repository.
@freezed
abstract class RatingModel with _$RatingModel {
  const factory RatingModel({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'driver_id') required String driverId,
    required int rating,
    @JsonKey(name: 'created_at') required String createdAt,
    String? comment,
  }) = _RatingModel;

  const RatingModel._();

  factory RatingModel.fromJson(Map<String, dynamic> json) =>
      _$RatingModelFromJson(json);

  /// Convert to a domain entity.
  Rating toEntity() => Rating(
        id: RatingId(id),
        tripId: TripId(tripId),
        studentId: UserId(studentId),
        driverId: DriverId(driverId),
        rating: rating,
        createdAt: DateTime.parse(createdAt),
        comment: comment,
      );
}
