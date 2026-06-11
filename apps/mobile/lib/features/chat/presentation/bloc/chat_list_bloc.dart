import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart'
    show ChatBloc;
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_state.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart'
    show NotificationsBloc;

part 'chat_list_event.dart';

/// BLoC for the conversations list page.
///
/// Mirrors the [ChatBloc] / [NotificationsBloc] pattern: an initial
/// load followed by a realtime subscription that pushes updates.
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  /// Creates a [ChatListBloc] with the given [chatRepository].
  ChatListBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatListState.initial()) {
    on<ChatListLoadRequested>(_onLoadRequested);
    on<ChatListRefreshRequested>(_onRefreshRequested);
    on<ChatListClosed>(_onClosed);

    on<_ChatListUpdated>(_onUpdated);
    on<_ChatListStreamErrored>(_onStreamErrored);
  }

  final ChatRepository _chatRepository;
  StreamSubscription<List<Conversation>>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    ChatListLoadRequested event,
    Emitter<ChatListState> emit,
  ) async {
    await _subscription?.cancel();
    emit(const ChatListState.loading());

    final initial = await _chatRepository.getMyConversations();
    if (isClosed) return;
    initial.fold(
      (Failure failure) => emit(ChatListState.error(failure: failure)),
      (List<Conversation> list) =>
          emit(ChatListState.loaded(conversations: list)),
    );

    _subscription = _chatRepository.watchMyConversations().listen(
          (List<Conversation> list) => add(_ChatListUpdated(list)),
          onError: (Object e) => add(
            _ChatListStreamErrored(ServerFailure(message: e.toString())),
          ),
        );
  }

  Future<void> _onRefreshRequested(
    ChatListRefreshRequested event,
    Emitter<ChatListState> emit,
  ) async {
    final result = await _chatRepository.getMyConversations();
    if (isClosed) return;
    result.fold(
      (Failure failure) => emit(ChatListState.error(failure: failure)),
      (List<Conversation> list) =>
          emit(ChatListState.loaded(conversations: list)),
    );
  }

  void _onUpdated(
    _ChatListUpdated event,
    Emitter<ChatListState> emit,
  ) {
    final current = state;
    if (current is ChatListLoaded) {
      final merged = event.conversations.map((newConv) {
        final oldConv = current.conversations.cast<Conversation?>().firstWhere(
              (c) => c!.id == newConv.id,
              orElse: () => null,
            );
        if (oldConv != null) {
          return newConv.copyWith(
            routeName: newConv.routeName ?? oldConv.routeName,
            otherUserName: newConv.otherUserName ?? oldConv.otherUserName,
          );
        }
        return newConv;
      }).toList();
      emit(ChatListState.loaded(conversations: merged));
    } else {
      emit(ChatListState.loaded(conversations: event.conversations));
    }
  }

  void _onStreamErrored(
    _ChatListStreamErrored event,
    Emitter<ChatListState> emit,
  ) {
    final current = state.maybeWhen(
      loaded: (list) => list,
      orElse: () => const <Conversation>[],
    );
    emit(ChatListState.loaded(conversations: current));
  }

  void _onClosed(ChatListClosed event, Emitter<ChatListState> emit) {
    _subscription?.cancel();
    _subscription = null;
    emit(const ChatListState.initial());
  }
}
