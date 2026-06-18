import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/chat/presentation/bloc/chat_state.dart';

part 'chat_event.dart';

/// BLoC for a single conversation view.
///
/// - On [ChatStarted] the bloc fetches the initial message list and
///   subscribes to realtime updates via [ChatRepository.watchMessages].
/// - On [ChatMessageSent] it persists the new message; the realtime
///   stream then propagates the row back into the UI automatically.
/// - On [ChatClosed] / `close` the subscription is cancelled.
sealed class ChatEvent extends Equatable {
  /// Constructor for [ChatEvent].
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// BLoC for a single conversation view.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  /// Creates an instance of [ChatBloc] with the given [chatRepository].
  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState.initial()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageRead>(_onMessageRead);
    on<ChatClosed>(_onClosed);

    on<_ChatMessagesUpdated>(_onMessagesUpdated);
    on<_ChatStreamErrored>(_onStreamErrored);
    on<_ChatSendCompleted>(_onSendCompleted);
  }

  final ChatRepository _chatRepository;
  StreamSubscription<List<Message>>? _messagesSubscription;
  ConversationId? _conversationId;

  /// Returns the current active [ConversationId].
  ConversationId? get conversationId =>
      _conversationId ??
      state.maybeWhen(
        loaded: (id, _, __) => id,
        orElse: () => null,
      );

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }

  List<Message> _currentMessages() {
    return state.maybeWhen(
      loaded: (_, msgs, __) => msgs,
      orElse: () => const <Message>[],
    );
  }

  Future<void> _onStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    await _messagesSubscription?.cancel();
    _conversationId = event.conversationId;
    emit(const ChatState.loading());

    final initial = await _chatRepository.getMessages(event.conversationId);
    if (isClosed) return;
    initial.fold(
      (Failure failure) => emit(ChatState.error(failure: failure)),
      (List<Message> messages) => emit(
        ChatState.loaded(
          conversationId: event.conversationId,
          messages: messages,
        ),
      ),
    );

    _messagesSubscription =
        _chatRepository.watchMessages(event.conversationId).listen(
              (List<Message> messages) => add(_ChatMessagesUpdated(messages)),
              onError: (Object e) => add(
                _ChatStreamErrored(ServerFailure(message: e.toString())),
              ),
            );
  }

  void _onMessagesUpdated(
    _ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    final id = conversationId;
    if (id == null) return;
    emit(ChatState.loaded(conversationId: id, messages: event.messages));
  }

  void _onStreamErrored(
    _ChatStreamErrored event,
    Emitter<ChatState> emit,
  ) {
    final id = conversationId;
    if (id == null) return;
    emit(
      ChatState.loaded(
        conversationId: id,
        messages: _currentMessages(),
      ),
    );
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final id = conversationId;
    if (id == null) return;

    final trimmed = event.body.trim();
    if (trimmed.isEmpty) return;

    final current = _currentMessages();

    emit(
      ChatState.loaded(
        conversationId: id,
        messages: current,
        isSending: true,
      ),
    );

    final result =
        await _chatRepository.sendMessage(conversationId: id, body: trimmed);

    if (isClosed) return;
    result.fold(
      (Failure failure) {
        emit(ChatState.loaded(conversationId: id, messages: current));
        emit(ChatState.error(failure: failure));
      },
      (Message _) => add(const _ChatSendCompleted()),
    );
  }

  void _onSendCompleted(
    _ChatSendCompleted event,
    Emitter<ChatState> emit,
  ) {
    final id = conversationId;
    if (id == null) return;

    emit(ChatState.loaded(conversationId: id, messages: _currentMessages()));
  }

  Future<void> _onMessageRead(
    ChatMessageRead event,
    Emitter<ChatState> emit,
  ) async {
    await _chatRepository.markAsRead(event.messageId);
  }

  void _onClosed(ChatClosed event, Emitter<ChatState> emit) {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _conversationId = null;
    emit(const ChatState.initial());
  }
}

/// Internal event: realtime subscription delivered new messages.
class _ChatMessagesUpdated extends ChatEvent {
  const _ChatMessagesUpdated(this.messages);
  final List<Message> messages;

  @override
  List<Object?> get props => [messages];
}

/// Internal event: realtime subscription errored.
class _ChatStreamErrored extends ChatEvent {
  const _ChatStreamErrored(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Internal event: send completed; the realtime stream will deliver the
/// new message, so we just clear the `isSending` flag.
class _ChatSendCompleted extends ChatEvent {
  const _ChatSendCompleted();
}
