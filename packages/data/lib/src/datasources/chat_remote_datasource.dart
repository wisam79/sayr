import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Chat conversations + messages remote operations.
abstract class ChatRemoteDatasource {
  /// Fetches the current user's conversations (driver or student side).
  Future<List<Map<String, dynamic>>> getMyConversations(String currentUserId);

  /// Realtime stream of the current user's conversations.
  Stream<List<Map<String, dynamic>>> watchMyConversations(String currentUserId);

  /// Fetches a single conversation by route + student.
  Future<Map<String, dynamic>?> getConversation({
    required String routeId,
    required String studentId,
  });

  /// Creates a new conversation.
  Future<Map<String, dynamic>> createConversation({
    required String routeId,
    required String studentId,
    required String driverUserId,
  });

  /// Fetches the most recent 50 messages of a conversation.
  Future<List<Map<String, dynamic>>> getMessages(String conversationId);

  /// Realtime stream of messages in a conversation.
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId);

  /// Sends a new message.
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  });

  /// Marks a single message as read.
  Future<void> markMessageAsRead({
    required String messageId,
    required String readAt,
  });

  /// RPC-backed unread chat count for the current user.
  Future<int> getUnreadChatCount();

  /// Updates the conversation's preview + last_message_at fields.
  Future<void> updateConversationPreview({
    required String conversationId,
    required String body,
    required String updatedAt,
  });
}

@LazySingleton(as: ChatRemoteDatasource)
class ChatRemoteDatasourceImpl implements ChatRemoteDatasource {
  ChatRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;

  @override
  Future<List<Map<String, dynamic>>> getMyConversations(
    String currentUserId,
  ) async {
    final response = await _client
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

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMyConversations(
    String currentUserId,
  ) =>
      _client
          .from('conversations')
          .stream(primaryKey: ['id'])
          .order('updated_at')
          .map((rows) => rows.cast<Map<String, dynamic>>());

  @override
  Future<Map<String, dynamic>?> getConversation({
    required String routeId,
    required String studentId,
  }) =>
      _client
          .from('conversations')
          .select()
          .eq('route_id', routeId)
          .eq('student_id', studentId)
          .maybeSingle();

  @override
  Future<Map<String, dynamic>> createConversation({
    required String routeId,
    required String studentId,
    required String driverUserId,
  }) async {
    final response = await _client
        .from('conversations')
        .insert({
          'route_id': routeId,
          'student_id': studentId,
          'driver_user_id': driverUserId,
        })
        .select()
        .single();
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(50);
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) =>
      _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .map((rows) => rows.cast<Map<String, dynamic>>());

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'body': body,
        })
        .select()
        .single();
    return response;
  }

  @override
  Future<void> markMessageAsRead({
    required String messageId,
    required String readAt,
  }) async {
    await _client.from('messages').update({
      'is_read': true,
      'read_at': readAt,
    }).eq('id', messageId);
  }

  @override
  Future<int> getUnreadChatCount() => _client.rpc<int>('get_unread_count');

  @override
  Future<void> updateConversationPreview({
    required String conversationId,
    required String body,
    required String updatedAt,
  }) async {
    final preview = body.length > 100 ? body.substring(0, 100) : body;
    await _client.from('conversations').update({
      'last_message_at': updatedAt,
      'last_message_preview': preview,
    }).eq('id', conversationId);
  }
}
