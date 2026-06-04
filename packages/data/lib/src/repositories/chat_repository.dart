import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../datasources/remote_datasource.dart';
import '../datasources/local_datasource.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

/// Concrete implementation of ChatRepository using Remote and Local data sources.
@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final RemoteDatasource _remoteDatasource;
  final LocalDatasource _localDatasource;

  ChatRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  @override
  Future<Either<Failure, List<Conversation>>> getMyConversations() async {
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, List<Conversation>>(UnauthorizedFailure());
      }

      final response =
          await _remoteDatasource.getMyConversations(currentUserId);
      final conversations = response.map((json) {
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

      return Right<Failure, List<Conversation>>(conversations);
    } catch (e) {
      return Left<Failure, List<Conversation>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Stream<List<Conversation>> watchMyConversations() {
    final currentUserId = _remoteDatasource.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
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
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, Conversation>(UnauthorizedFailure());
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
        return Right<Failure, Conversation>(
          ConversationModel.fromJson(map).toEntity(),
        );
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
      return Right<Failure, Conversation>(
        ConversationModel.fromJson(map).toEntity(),
      );
    } catch (e) {
      return Left<Failure, Conversation>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(
      ConversationId conversationId) async {
    try {
      final response =
          await _remoteDatasource.getMessages(conversationId.value);
      final messages = response
          .map((json) => MessageModel.fromJson(json).toEntity())
          .toList();
      return Right<Failure, List<Message>>(messages);
    } catch (e) {
      return Left<Failure, List<Message>>(
        ServerFailure(message: e.toString()),
      );
    }
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
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, Message>(UnauthorizedFailure());
      }

      final response = await _remoteDatasource.sendMessage(
        conversationId: conversationId.value,
        senderId: currentUserId,
        body: body,
      );

      await _remoteDatasource.updateConversationPreview(
        conversationId: conversationId.value,
        body: body,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return Right<Failure, Message>(
          MessageModel.fromJson(response).toEntity());
    } catch (e) {
      return Left<Failure, Message>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(MessageId messageId) async {
    try {
      await _remoteDatasource.markMessageAsRead(
        messageId: messageId.value,
        readAt: DateTime.now().toUtc().toIso8601String(),
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final result = await _remoteDatasource.getUnreadChatCount();
      return Right<Failure, int>(result);
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  String? _resolveOtherUserName({
    required Map<String, dynamic> json,
    required String? currentUserId,
  }) {
    if (currentUserId == null) return null;
    final dynamic student = json['student'];
    final dynamic driver = json['driver'];

    final bool isStudent = json['student_id'] == currentUserId;
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
