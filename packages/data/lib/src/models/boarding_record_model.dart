import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'boarding_record_model.freezed.dart';
part 'boarding_record_model.g.dart';

@freezed
abstract class BoardingRecordModel with _$BoardingRecordModel {
  const factory BoardingRecordModel({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'boarded_at') required DateTime boardedAt,
    @JsonKey(name: 'subscription_id') String? subscriptionId,
    @JsonKey(name: 'student_name') String? studentName,
    @JsonKey(name: 'boarding_method') @Default('qr_scan') String boardingMethod,
  }) = _BoardingRecordModel;

  const BoardingRecordModel._();

  factory BoardingRecordModel.fromJson(Map<String, dynamic> json) =>
      _$BoardingRecordModelFromJson(json);

  BoardingRecord toEntity() {
    final method = switch (boardingMethod) {
      'qr_scan' => BoardingMethod.qrScan,
      'manual' => BoardingMethod.manual,
      'proximity' => BoardingMethod.selfCheckIn,
      'self_check_in' => BoardingMethod.selfCheckIn,
      _ => BoardingMethod.qrScan,
    };
    return BoardingRecord(
      id: BoardingId(id),
      tripId: TripId(tripId),
      subscriptionId:
          subscriptionId != null ? SubscriptionId(subscriptionId!) : null,
      studentId: UserId(studentId),
      studentName: studentName,
      boardedAt: boardedAt,
      boardingMethod: method,
    );
  }
}
