part of 'chat_bloc.dart';

/// Open a conversation and start listening to realtime messages.
class ChatStarted extends ChatEvent {
  const ChatStarted(this.conversationId);
  final ConversationId conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Send a new message. The realtime stream subscription will append the
/// row to the messages list when the insert propagates.
class ChatMessageSent extends ChatEvent {
  const ChatMessageSent(this.body);
  final String body;

  @override
  List<Object?> get props => [body];
}

/// Mark a message as read (called when an incoming bubble is rendered).
class ChatMessageRead extends ChatEvent {
  const ChatMessageRead(this.messageId);
  final MessageId messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Close the conversation and stop listening to the realtime stream.
class ChatClosed extends ChatEvent {
  const ChatClosed();
}
