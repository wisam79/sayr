import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// A notification sent to a user.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    @JsonKey(fromJson: notificationIdFromJson, toJson: notificationIdToJson)
    required NotificationId id,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId userId,
    required String title,
    required String body,
    required bool isRead,
    required DateTime createdAt,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
