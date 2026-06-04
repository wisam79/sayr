import 'package:equatable/equatable.dart';

import '../value_objects/ids.dart';

/// A notification sent to a user.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data = const <String, dynamic>{},
  });

  /// Unique notification ID.
  final NotificationId id;

  /// The recipient user.
  final UserId userId;

  /// Notification title.
  final String title;

  /// Notification body.
  final String body;

  /// Whether the notification has been read.
  final bool isRead;

  /// When the notification was created.
  final DateTime createdAt;

  /// Optional payload data.
  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        body,
        isRead,
        createdAt,
        data,
      ];
}
