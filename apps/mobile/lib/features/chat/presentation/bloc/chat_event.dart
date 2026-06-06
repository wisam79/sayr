part of 'chat_bloc.dart';

/// Open a conversation and start listening to realtime messages.
class ChatStarted extends ChatEvent {
  /// Creates a [ChatStarted] event.
  const ChatStarted(this.conversationId);

  /// The ID of the conversation to start.
  final ConversationId conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Send a new message. The realtime stream subscription will append the
/// row to the messages list when the insert propagates.
class ChatMessageSent extends ChatEvent {
  /// Creates a [ChatMessageSent] event.
  const ChatMessageSent(this.body);

  /// The body text of the message being sent.
  final String body;

  @override
  List<Object?> get props => [body];
}

/// Mark a message as read (called when an incoming bubble is rendered).
class ChatMessageRead extends ChatEvent {
  /// Creates a [ChatMessageRead] event.
  const ChatMessageRead(this.messageId);

  /// The ID of the message to mark as read.
  final MessageId messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Close the conversation and stop listening to the realtime stream.
class ChatClosed extends ChatEvent {
  /// Creates a [ChatClosed] event.
  const ChatClosed();
}
