import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/conversation_model.dart';
import 'package:sayr_data/src/models/message_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Concrete implementation of ChatRepository using Remote data source.
@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl extends BaseRepository implements ChatRepository {
  ChatRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required super.talker,
  }) : _remoteDatasource = remoteDatasource;
  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, List<Conversation>>> getMyConversations() async {
    return guard(() async {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
      }

      final response =
          await _remoteDatasource.getMyConversations(currentUserId);
      return response.map((json) {
        final otherName =
            _resolveOtherUserName(json: json, currentUserId: currentUserId);
        final routeName = _resolveRouteName(json: json);
        final map = {
          ...json,
          'route_name': routeName,
          'other_user_name': otherName,
        };
        return ConversationModel.fromJson(map).toEntity();
      }).toList();
    });
  }

  @override
  Stream<List<Conversation>> watchMyConversations() {
    final currentUserId = _remoteDatasource.currentUser?.id;
    if (currentUserId == null) {
      // Surface the auth failure instead of masquerading as an empty list,
      // otherwise the UI would render "no conversations" for an unauthenticated
      // user rather than prompting them to sign in.
      return Stream.error(const UnauthorizedFailure());
    }
    return _remoteDatasource.watchMyConversations(currentUserId).map((rows) {
      return rows
          .where(
        (r) =>
            r['student_id'] == currentUserId ||
            r['driver_user_id'] == currentUserId,
      )
          .map((json) {
        final otherName =
            _resolveOtherUserName(json: json, currentUserId: currentUserId);
        final routeName = _resolveRouteName(json: json);
        final map = {
          ...json,
          'route_name': routeName,
          'other_user_name': otherName,
        };
        return ConversationModel.fromJson(map).toEntity();
      }).toList();
    });
  }

  @override
  Future<Either<Failure, Conversation>> getOrCreateConversation({
    required RouteId routeId,
    required UserId driverUserId,
  }) async {
    return guard(() async {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
      }

      final existing = await _remoteDatasource.getConversation(
        routeId: routeId.value,
        studentId: currentUserId,
      );

      if (existing != null) {
        final otherName =
            _resolveOtherUserName(json: existing, currentUserId: currentUserId);
        final routeName = _resolveRouteName(json: existing);
        final map = {
          ...existing,
          'route_name': routeName,
          'other_user_name': otherName,
        };
        return ConversationModel.fromJson(map).toEntity();
      }

      final created = await _remoteDatasource.createConversation(
        routeId: routeId.value,
        studentId: currentUserId,
        driverUserId: driverUserId.value,
      );

      final otherName =
          _resolveOtherUserName(json: created, currentUserId: currentUserId);
      final routeName = _resolveRouteName(json: created);
      final map = {
        ...created,
        'route_name': routeName,
        'other_user_name': otherName,
      };
      return ConversationModel.fromJson(map).toEntity();
    });
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    ConversationId conversationId,
  ) async {
    return guard(() async {
      final response =
          await _remoteDatasource.getMessages(conversationId.value);
      return response
          .map((json) => MessageModel.fromJson(json).toEntity())
          .toList();
    });
  }

  @override
  Stream<List<Message>> watchMessages(ConversationId conversationId) {
    return _remoteDatasource.watchMessages(conversationId.value).map(
          (rows) => rows
              .map((json) => MessageModel.fromJson(json).toEntity())
              .toList(),
        );
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required ConversationId conversationId,
    required String body,
  }) async {
    return guard(() async {
      // Basic HTML tag stripping sanitization
      final sanitizedBody = body.replaceAll(RegExp('<[^>]*>'), '').trim();

      if (sanitizedBody.isEmpty) {
        throw const ValidationFailure(message: 'Message body cannot be empty');
      }
      if (sanitizedBody.length > 2000) {
        throw const ValidationFailure(
          message: 'Message body cannot exceed 2000 characters',
        );
      }

      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
      }

      final response = await _remoteDatasource.sendMessage(
        conversationId: conversationId.value,
        senderId: currentUserId,
        body: sanitizedBody,
      );

      final createdAt = response['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String();

      // Best-effort: update conversation preview, do not crash if it fails
      try {
        await _remoteDatasource.updateConversationPreview(
          conversationId: conversationId.value,
          body: sanitizedBody,
          updatedAt: createdAt,
        );
      } catch (e, st) {
        log.warning(
          'ChatRepository: Failed to update conversation preview (best-effort)',
          e,
          st,
        );
      }
      return MessageModel.fromJson(response).toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(MessageId messageId) async {
    return guard(() async {
      await _remoteDatasource.markMessageAsRead(
        messageId: messageId.value,
        readAt: DateTime.now().toUtc().toIso8601String(),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    return guard(() async {
      return _remoteDatasource.getUnreadChatCount();
    });
  }

  String? _resolveOtherUserName({
    required Map<String, dynamic> json,
    required String? currentUserId,
  }) {
    if (currentUserId == null) return null;
    final dynamic student = json['student'];
    final dynamic driver = json['driver'];

    final isStudent = json['student_id'] == currentUserId;
    final dynamic other = isStudent ? driver : student;
    if (other is Map<String, dynamic>) {
      return other['full_name'] as String?;
    }
    return null;
  }

  String? _resolveRouteName({required Map<String, dynamic> json}) {
    final dynamic routes = json['routes'];
    if (routes is Map<String, dynamic>) {
      return routes['title'] as String?;
    }
    if (routes is List && routes.isNotEmpty) {
      final dynamic first = routes.first;
      if (first is Map<String, dynamic>) {
        return first['title'] as String?;
      }
    }
    return null;
  }
}
