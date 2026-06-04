import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
abstract class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required String id,
    @JsonKey(name: 'route_id') required String routeId,
    @JsonKey(name: 'student_id') required String studentId,
    @JsonKey(name: 'driver_user_id') required String driverUserId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'last_message_preview') String? lastMessagePreview,
    @JsonKey(name: 'route_name') String? routeName,
    @JsonKey(name: 'other_user_name') String? otherUserName,
  }) = _ConversationModel;

  const ConversationModel._();

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Conversation toEntity() => Conversation(
        id: ConversationId(id),
        routeId: RouteId(routeId),
        studentId: UserId(studentId),
        driverUserId: UserId(driverUserId),
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastMessageAt: lastMessageAt,
        lastMessagePreview: lastMessagePreview,
        routeName: routeName,
        otherUserName: otherUserName,
      );
}
