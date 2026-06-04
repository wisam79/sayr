import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

@freezed
abstract class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    required String id,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'route_id') required String routeId,
    required String status,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt,
  }) = _SubscriptionModel;

  const SubscriptionModel._();

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  Subscription toEntity() => Subscription(
        id: SubscriptionId(id),
        studentId: UserId(studentId),
        routeId: RouteId(routeId),
        status: SubscriptionStatus.fromString(status),
        startDate: startDate,
        endDate: endDate,
        cancelledAt: cancelledAt,
      );
}
