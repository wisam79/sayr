import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'boarding_record_model.freezed.dart';
part 'boarding_record_model.g.dart';

@freezed
abstract class BoardingRecordModel with _$BoardingRecordModel {
  const factory BoardingRecordModel({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'subscription_id') required String subscriptionId,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'boarded_at') required DateTime boardedAt, @JsonKey(name: 'student_name') String? studentName,
    @JsonKey(name: 'boarding_method') @Default('qr_scan') String boardingMethod,
  }) = _BoardingRecordModel;

  const BoardingRecordModel._();

  factory BoardingRecordModel.fromJson(Map<String, dynamic> json) =>
      _$BoardingRecordModelFromJson(json);

  BoardingRecord toEntity() => BoardingRecord(
        id: BoardingId(id),
        tripId: TripId(tripId),
        subscriptionId: SubscriptionId(subscriptionId),
        studentId: UserId(studentId),
        studentName: studentName,
        boardedAt: boardedAt,
        boardingMethod: boardingMethod,
      );
}
