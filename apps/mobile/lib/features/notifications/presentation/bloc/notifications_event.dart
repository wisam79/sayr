part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the user's notifications and start listening for realtime updates.
class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

/// Re-fetch the list (pull-to-refresh / manual).
class NotificationsRefreshRequested extends NotificationsEvent {
  const NotificationsRefreshRequested();
}

/// Mark a single notification as read.
class NotificationMarkedRead extends NotificationsEvent {
  const NotificationMarkedRead(this.id);
  final NotificationId id;

  @override
  List<Object?> get props => [id];
}

/// Mark every notification for the current user as read.
class NotificationsMarkAllRead extends NotificationsEvent {
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
