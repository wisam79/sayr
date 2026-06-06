part of 'notifications_bloc.dart';

/// Base class for all notification events.
sealed class NotificationsEvent extends Equatable {
  /// Constructor for [NotificationsEvent].
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the user's notifications and start listening for realtime updates.
class NotificationsLoadRequested extends NotificationsEvent {
  /// Creates a [NotificationsLoadRequested] event.
  const NotificationsLoadRequested();
}

/// Re-fetch the list (pull-to-refresh / manual).
class NotificationsRefreshRequested extends NotificationsEvent {
  /// Creates a [NotificationsRefreshRequested] event.
  const NotificationsRefreshRequested();
}

/// Mark a single notification as read.
class NotificationMarkedRead extends NotificationsEvent {
  /// Creates a [NotificationMarkedRead] event.
  const NotificationMarkedRead(this.id);

  /// The ID of the notification to mark as read.
  final NotificationId id;

  @override
  List<Object?> get props => [id];
}

/// Mark every notification for the current user as read.
class NotificationsMarkAllRead extends NotificationsEvent {
  /// Creates a [NotificationsMarkAllRead] event.
  const NotificationsMarkAllRead();
}

class _NotificationsUpdated extends NotificationsEvent {
  const _NotificationsUpdated(this.notifications);
  final List<AppNotification> notifications;

  @override
  List<Object?> get props => [notifications];
}

class _NotificationsStreamErrored extends NotificationsEvent {
  const _NotificationsStreamErrored(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Request registering/updating the device push token on the server.
class NotificationRegisterTokenRequested extends NotificationsEvent {
  const NotificationRegisterTokenRequested({
    required this.fcmToken,
    required this.platform,
    this.deviceId,
  });

  final String fcmToken;
  final String platform;
  final String? deviceId;

  @override
  List<Object?> get props => [fcmToken, platform, deviceId];
}
