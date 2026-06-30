import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'notification.freezed.dart';
/// A notification sent to a user.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required NotificationId id,
    required UserId userId,
    required String title,
    required String body,
    required bool isRead,
    required DateTime createdAt,
    @Default(<String, String>{}) Map<String, String> data,
  }) = _AppNotification;

  }
