import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'message.freezed.dart';

/// A chat message in a conversation.
@freezed
abstract class Message with _$Message {
  const factory Message({
    required MessageId id,
    required ConversationId conversationId,
    required UserId senderId,
    required String body,
    required bool isRead,
    required DateTime createdAt,
  }) = _Message;
}

/// A conversation between users (e.g., student + driver).
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required ConversationId id,
    required RouteId routeId,
    required UserId studentId,
    required UserId driverUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? routeName,
    String? otherUserName,
  }) = _Conversation;
}
