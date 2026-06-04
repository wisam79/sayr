import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../supabase/supabase_client.dart';

/// Repository for chat operations (conversations + messages).
@lazySingleton
class ChatRepository {
  ChatRepository({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// Get all conversations the current user participates in, ordered
  /// by most recent message. Joins with [routes] and [profiles] to
  /// denormalize the route title and the other participant's name.
  Future<Either<Failure, List<Conversation>>> getMyConversations() async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, List<Conversation>>(UnauthorizedFailure());
      }

      final response = await _supabase.client
          .from('conversations')
          .select('''
            id,
            route_id,
            student_id,
            driver_user_id,
            last_message_at,
            last_message_preview,
            created_at,
            updated_at,
            routes:route_id ( title ),
            student:profiles!conversations_student_id_fkey ( full_name ),
            driver:profiles!conversations_driver_user_id_fkey ( full_name )
          ''')
          .or('student_id.eq.$currentUserId,driver_user_id.eq.$currentUserId')
          .order('updated_at', ascending: false);

      final conversations = (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => _conversationFromJson(json, currentUserId))
          .toList();
      return Right<Failure, List<Conversation>>(conversations);
    } catch (e) {
      return Left<Failure, List<Conversation>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Subscribe to changes on the user's conversations list.
  Stream<List<Conversation>> watchMyConversations() {
    return _supabase.client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((rows) {
          final currentUserId = _supabase.client.auth.currentUser?.id;
          return rows
              .cast<Map<String, dynamic>>()
              .where(
                (r) =>
                    r['student_id'] == currentUserId ||
                    r['driver_user_id'] == currentUserId,
              )
              .map((json) => _conversationFromJson(json, currentUserId))
              .toList();
        });
  }

  /// Look up an existing conversation for (route, student) or create one.
  /// Returns the conversation row regardless.
  Future<Either<Failure, Conversation>> getOrCreateConversation({
    required RouteId routeId,
    required UserId driverUserId,
  }) async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, Conversation>(UnauthorizedFailure());
      }

      final existing = await _supabase.client
          .from('conversations')
          .select()
          .eq('route_id', routeId.value)
          .eq('student_id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        return Right<Failure, Conversation>(
          _conversationFromJson(
            existing as Map<String, dynamic>,
            currentUserId,
          ),
        );
      }

      final created = await _supabase.client
          .from('conversations')
          .insert({
            'route_id': routeId.value,
            'student_id': currentUserId,
            'driver_user_id': driverUserId.value,
          })
          .select()
          .single();

      return Right<Failure, Conversation>(
        _conversationFromJson(created, currentUserId),
      );
    } catch (e) {
      return Left<Failure, Conversation>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Get messages for a specific conversation.
  Future<Either<Failure, List<Message>>> getMessages(
    ConversationId conversationId,
  ) async {
    try {
      final response = await _supabase.client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId.value)
          .order('created_at', ascending: true)
          .limit(50);

      final messages = (response as List)
          .cast<Map<String, dynamic>>()
          .map(_messageFromJson)
          .toList();
      return Right<Failure, List<Message>>(messages);
    } catch (e) {
      return Left<Failure, List<Message>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Subscribe to messages via Realtime.
  Stream<List<Message>> watchMessages(ConversationId conversationId) {
    return _supabase.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId.value)
        .map((rows) => rows.map(_messageFromJson).toList());
  }

  /// Send a new message. Realtime stream will propagate the new row to
  /// [watchMessages] subscribers automatically.
  Future<Either<Failure, Message>> sendMessage({
    required ConversationId conversationId,
    required String body,
  }) async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, Message>(UnauthorizedFailure());
      }

      final response = await _supabase.client
          .from('messages')
          .insert({
            'conversation_id': conversationId.value,
            'sender_id': currentUserId,
            'body': body,
          })
          .select()
          .single();

      await _updateConversationPreview(conversationId.value, body);
      return Right<Failure, Message>(_messageFromJson(response));
    } catch (e) {
      return Left<Failure, Message>(ServerFailure(message: e.toString()));
    }
  }

  /// Mark a message as read.
  Future<Either<Failure, Unit>> markAsRead(MessageId messageId) async {
    try {
      await _supabase.client.from('messages').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', messageId.value);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  /// Get total unread message count via the existing RPC.
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final result = await _supabase.client.rpc<int>('get_unread_count');
      return Right<Failure, int>(result);
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  Future<void> _updateConversationPreview(
    String conversationId,
    String body,
  ) async {
    final preview = body.length > 100 ? body.substring(0, 100) : body;
    await _supabase.client.from('conversations').update({
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      'last_message_preview': preview,
    }).eq('id', conversationId);
  }

  Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: MessageId(json['id'] as String),
      conversationId: ConversationId(json['conversation_id'] as String),
      senderId: UserId(json['sender_id'] as String),
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Conversation _conversationFromJson(
    Map<String, dynamic> json,
    String? currentUserId,
  ) {
    final String? otherName = _resolveOtherUserName(
      json: json,
      currentUserId: currentUserId,
    );
    final String? routeName = _resolveRouteName(json: json);

    final dynamic lastAt = json['last_message_at'];
    return Conversation(
      id: ConversationId(json['id'] as String),
      routeId: RouteId(json['route_id'] as String),
      studentId: UserId(json['student_id'] as String),
      driverUserId: UserId(json['driver_user_id'] as String),
      lastMessageAt: lastAt is String ? DateTime.parse(lastAt) : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      routeName: routeName,
      otherUserName: otherName,
    );
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
