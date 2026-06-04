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
    required this.studentId,
    required this.driverUserId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.routeName,
    this.otherUserName,
  });

  /// Unique conversation ID.
  final ConversationId id;

  /// The route this conversation is about.
  final RouteId routeId;

  /// The student who initiated the conversation.
  final UserId studentId;

  /// The driver who is the other participant.
  final UserId driverUserId;

  /// When the conversation was created.
  final DateTime createdAt;

  /// When the conversation was last updated.
  final DateTime updatedAt;

  /// Timestamp of the most recent message, if any.
  final DateTime? lastMessageAt;

  /// Preview of the most recent message, truncated to 100 chars.
  final String? lastMessagePreview;

  /// Route title (denormalized for list rendering, optional).
  final String? routeName;

  /// Display name of the other participant (denormalized, optional).
  final String? otherUserName;

  @override
  List<Object?> get props => [
        id,
        routeId,
        studentId,
        driverUserId,
        createdAt,
        updatedAt,
        lastMessageAt,
        lastMessagePreview,
        routeName,
        otherUserName,
      ];
}
