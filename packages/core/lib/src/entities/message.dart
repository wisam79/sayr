import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// A chat message in a conversation.
@freezed
abstract class Message with _$Message {
  const factory Message({
    @JsonKey(fromJson: messageIdFromJson, toJson: messageIdToJson)
    required MessageId id,
    @JsonKey(fromJson: conversationIdFromJson, toJson: conversationIdToJson)
    required ConversationId conversationId,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId senderId,
    required String body,
    required bool isRead,
    required DateTime createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

/// A conversation between users (e.g., student + driver).
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    @JsonKey(fromJson: conversationIdFromJson, toJson: conversationIdToJson)
    required ConversationId id,
    @JsonKey(fromJson: routeIdFromJson, toJson: routeIdToJson)
    required RouteId routeId,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId studentId,
    @JsonKey(fromJson: userIdFromJson, toJson: userIdToJson)
    required UserId driverUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? routeName,
    String? otherUserName,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
