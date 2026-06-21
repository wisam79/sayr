import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';

part 'notifications_event.dart';

/// BLoC for the notifications inbox.
///
/// Mirrors `ChatBloc`: initial load via [NotificationsLoadRequested], then
/// realtime updates via [_NotificationsUpdated] dispatched by the stream
/// subscription.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  /// Creates a [NotificationsBloc] with the given [notificationsRepository].
  NotificationsBloc({required NotificationsRepository notificationsRepository})
      : _repository = notificationsRepository,
        super(const NotificationsState.initial()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationsRefreshRequested>(_onRefreshRequested);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationsMarkAllRead>(_onMarkAllRead);

    on<_NotificationsUpdated>(_onUpdated);
    on<_NotificationsStreamErrored>(_onStreamErrored);
    on<NotificationRegisterTokenRequested>(_onRegisterTokenRequested);
  }

  final NotificationsRepository _repository;
  StreamSubscription<List<AppNotification>>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  List<AppNotification> _currentList() {
    return state.maybeWhen(
      loaded: (list, _) => list,
      orElse: () => const <AppNotification>[],
    );
  }

  int _currentUnread() {
    return _currentList().where((n) => !n.isRead).length;
  }

  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _subscription?.cancel();
    emit(const NotificationsState.loading());

    final initial = await _repository.getMyNotifications();
    if (isClosed) return;
    initial.fold(
      (Failure failure) => emit(NotificationsState.error(failure: failure)),
      (List<AppNotification> list) => emit(
        NotificationsState.loaded(
          notifications: list,
          unreadCount: list.where((n) => !n.isRead).length,
        ),
      ),
    );

    _subscription = _repository.watchMyNotifications().listen(
          (List<AppNotification> list) => add(_NotificationsUpdated(list)),
          onError: (Object e) => add(
            _NotificationsStreamErrored(ServerFailure(message: e.toString())),
          ),
        );
  }

  Future<void> _onRefreshRequested(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await _repository.getMyNotifications();
    if (isClosed) return;
    result.fold(
      (Failure failure) => emit(NotificationsState.error(failure: failure)),
      (List<AppNotification> list) => emit(
        NotificationsState.loaded(
          notifications: list,
          unreadCount: list.where((n) => !n.isRead).length,
        ),
      ),
    );
  }

  void _onUpdated(
    _NotificationsUpdated event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      NotificationsState.loaded(
        notifications: event.notifications,
        unreadCount: event.notifications.where((n) => !n.isRead).length,
      ),
    );
  }

  void _onStreamErrored(
    _NotificationsStreamErrored event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      NotificationsState.loaded(
        notifications: _currentList(),
        unreadCount: _currentUnread(),
      ),
    );
  }

  Future<void> _onMarkedRead(
    NotificationMarkedRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _currentList();
    final updated = current
        .map(
          (n) => n.id == event.id ? n.copyWith(isRead: true) : n,
        )
        .toList();

    emit(
      NotificationsState.loaded(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      ),
    );

    await _repository.markAsRead(event.id);
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _currentList();
    final updated = current
        .map(
          (n) => n.copyWith(isRead: true),
        )
        .toList();

    emit(
      NotificationsState.loaded(
        notifications: updated,
      ),
    );

    await _repository.markAllAsRead();
  }

  Future<void> _onRegisterTokenRequested(
    NotificationRegisterTokenRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repository.registerPushToken(
      fcmToken: event.fcmToken,
      platform: event.platform,
      deviceId: event.deviceId,
    );
  }
}
