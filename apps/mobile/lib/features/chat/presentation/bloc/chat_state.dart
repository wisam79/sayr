import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart'
    show ChatBloc;

part 'chat_state.freezed.dart';

/// State for [ChatBloc].
///
/// - [ChatInitial] / [ChatLoading] — initial load
/// - [ChatLoaded] — messages list is available; `isSending` indicates an
///   outgoing message is being persisted
/// - [ChatError] — terminal error
@freezed
sealed class ChatState with _$ChatState {
  const factory ChatState.initial() = ChatInitial;
  const factory ChatState.loading() = ChatLoading;

  const factory ChatState.loaded({
    required ConversationId conversationId,
    required List<Message> messages,
    @Default(false) bool isSending,
    Failure? sendError,
  }) = ChatLoaded;

  const factory ChatState.error({required Failure failure}) = ChatError;
}
