import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../supabase/supabase_client.dart';

/// Repository for in-app notifications.
///
/// Backed by the `notification_log` table in Supabase.
@lazySingleton
class NotificationsRepository {
  NotificationsRepository({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// Fetch the latest notifications for the current user.
  Future<Either<Failure, List<AppNotification>>> getMyNotifications({
    int limit = 50,
  }) async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, List<AppNotification>>(
          UnauthorizedFailure(),
        );
      }

      final response = await _supabase.client
          .from('notification_log')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      final notifications = (response as List)
          .cast<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();
      return Right<Failure, List<AppNotification>>(notifications);
    } catch (e) {
      return Left<Failure, List<AppNotification>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  /// Get the count of unread notifications.
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, int>(UnauthorizedFailure());
      }

      final response = await _supabase.client
          .from('notification_log')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('is_read', false);

      final int count = (response as List).length;
      return Right<Failure, int>(count);
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  /// Mark a single notification as read.
  Future<Either<Failure, Unit>> markAsRead(NotificationId id) async {
    try {
      await _supabase.client.from('notification_log').update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id.value);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  /// Mark every unread notification for the current user as read.
  Future<Either<Failure, Unit>> markAllAsRead() async {
    try {
      final currentUserId = _supabase.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, Unit>(UnauthorizedFailure());
      }

      await _supabase.client
          .from('notification_log')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', currentUserId)
          .eq('is_read', false);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  /// Subscribe to the user's notification stream.
  Stream<List<AppNotification>> watchMyNotifications() {
    final currentUserId = _supabase.client.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream<List<AppNotification>>.error(
        const UnauthorizedFailure(),
      );
    }

    return _supabase.client
        .from('notification_log')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .map((rows) => rows.map(_fromJson).toList());
  }

  /// Register (or refresh) the current device's FCM push token.
  Future<Either<Failure, Unit>> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  }) async {
    try {
      await _supabase.client.rpc<void>(
        'register_push_token',
        params: {
          'p_token': fcmToken,
          'p_platform': platform,
          if (deviceId != null) 'p_device_id': deviceId,
        },
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  AppNotification _fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    return AppNotification(
      id: NotificationId(json['id'] as String),
      userId: UserId(json['user_id'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const <String, dynamic>{},
    );
  }
}
