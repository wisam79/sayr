part of 'chat_list_bloc.dart';

/// Public events for [ChatListBloc].
sealed class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load + start realtime subscription.
class ChatListLoadRequested extends ChatListEvent {
  const ChatListLoadRequested();
}

/// Manual refresh (pull-to-refresh / retry).
class ChatListRefreshRequested extends ChatListEvent {
  const ChatListRefreshRequested();
}

/// Stop the realtime subscription and reset state.
class ChatListClosed extends ChatListEvent {
  const ChatListClosed();
}

/// Internal: realtime subscription delivered a new list.
class _ChatListUpdated extends ChatListEvent {
  const _ChatListUpdated(this.conversations);
  final List<Conversation> conversations;

  @override
  List<Object?> get props => [conversations];
}

/// Internal: realtime subscription errored.
class _ChatListStreamErrored extends ChatListEvent {
  const _ChatListStreamErrored(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
