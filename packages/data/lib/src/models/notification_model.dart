import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String title,
    required String body,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
  }) = _NotificationModel;

  const NotificationModel._();

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  AppNotification toEntity() => AppNotification(
        id: NotificationId(id),
        userId: UserId(userId),
        title: title,
        body: body,
        isRead: isRead,
        createdAt: createdAt,
        data: data.map((k, v) => MapEntry(k, v.toString())),
      );
}
