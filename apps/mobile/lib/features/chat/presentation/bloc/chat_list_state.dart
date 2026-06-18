import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_bloc.dart'
    show ChatListBloc;

part 'chat_list_state.freezed.dart';

/// State for [ChatListBloc].
@freezed
sealed class ChatListState with _$ChatListState {
  const factory ChatListState.initial() = ChatListInitial;
  const factory ChatListState.loading() = ChatListLoading;

  const factory ChatListState.loaded({
    required List<Conversation> conversations,
  }) = ChatListLoaded;

  const factory ChatListState.error({required Failure failure}) = ChatListError;
}
