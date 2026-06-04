import 'package:equatable/equatable.dart';

import '../value_objects/ids.dart';

/// A chat message in a conversation.
class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  /// Unique message ID.
  final MessageId id;

  /// The conversation this message belongs to.
  final ConversationId conversationId;

  /// The user who sent the message.
  final UserId senderId;

  /// Message body.
  final String body;

  /// Whether the message has been read by the recipient.
  final bool isRead;

  /// When the message was sent.
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        body,
        isRead,
        createdAt,
      ];
}

/// A conversation between users (e.g., student + driver).
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.routeId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique conversation ID.
  final ConversationId id;

  /// The route this conversation is about.
  final RouteId routeId;

  /// When the conversation was created.
  final DateTime createdAt;

  /// When the last message was sent.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, routeId, createdAt, updatedAt];
}
