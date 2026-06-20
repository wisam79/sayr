import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// In-app notification log + FCM push token registration.
abstract class NotificationRemoteDatasource {
  /// Fetches the user's most recent notification log entries.
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String userId,
    int limit = 50,
  });

  /// Returns the count of unread notifications for the user.
  Future<int> getUnreadNotificationCount(String userId);

  /// Marks a single notification log entry as read.
  Future<void> markNotificationAsRead({
    required String id,
    required String readAt,
  });

  /// Marks every unread notification log entry for the user as read.
  Future<void> markAllNotificationsAsRead({
    required String userId,
    required String readAt,
  });

  /// Realtime stream of the user's notification log.
  Stream<List<Map<String, dynamic>>> watchMyNotifications(String userId);

  /// Registers the device's FCM token via the `register_push_token` RPC.
  Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  });

  /// Deactivates all push tokens for the current user (called on logout).
  Future<void> deactivatePushTokens();
}

@LazySingleton(as: NotificationRemoteDatasource)
class NotificationRemoteDatasourceImpl implements NotificationRemoteDatasource {
  NotificationRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;

  @override
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String userId,
    int limit = 50,
  }) async {
    final response = await _client
        .from('notification_log')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response as Iterable);
  }

  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    final response = await _client
        .from('notification_log')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  @override
  Future<void> markNotificationAsRead({
    required String id,
    required String readAt,
  }) async {
    await _client.from('notification_log').update({
      'is_read': true,
      'read_at': readAt,
    }).eq('id', id);
  }

  @override
  Future<void> markAllNotificationsAsRead({
    required String userId,
    required String readAt,
  }) async {
    await _client
        .from('notification_log')
        .update({
          'is_read': true,
          'read_at': readAt,
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMyNotifications(String userId) =>
      _client
          .from('notification_log')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((List<Map<String, dynamic>> rows) => rows);

  @override
  Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  }) =>
      _client.rpc<void>(
        'register_push_token',
        params: {
          'p_token': fcmToken,
          'p_platform': platform,
          if (deviceId != null) 'p_device_id': deviceId,
        },
      );

  @override
  Future<void> deactivatePushTokens() =>
      _client.rpc<void>('deactivate_push_tokens');
}
