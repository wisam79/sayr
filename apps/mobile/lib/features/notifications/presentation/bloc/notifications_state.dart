import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart'
    show NotificationsBloc;

part 'notifications_state.freezed.dart';

/// State for [NotificationsBloc].
@freezed
sealed class NotificationsState with _$NotificationsState {
  const factory NotificationsState.initial() = NotificationsInitial;
  const factory NotificationsState.loading() = NotificationsLoading;

  const factory NotificationsState.loaded({
    required List<AppNotification> notifications,
    @Default(0) int unreadCount,
  }) = NotificationsLoaded;

  const factory NotificationsState.error({required Failure failure}) =
      NotificationsError;
}
