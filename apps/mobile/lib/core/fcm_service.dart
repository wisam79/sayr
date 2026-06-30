import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Simplified Firebase Cloud Messaging service using `awesome_notifications` for local alerts.
class FcmService {
  FcmService._();

  static Talker get _talker => sl<Talker>();

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Optional navigation callback. Receives the parsed type-safe [FcmPayload].
  static void Function(FcmPayload payload)? navigationHandler;

  /// Initialize FCM + awesome_notifications.
  static Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    if (_initialized) return;
    _initialized = true;

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'sayr_default',
          channelName: 'إشعارات سير',
          channelDescription: 'إشعارات تطبيق سير للنقل الجامعي',
          defaultColor: const Color(0xFF1E5BFF),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );

    // Request notifications permission.
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // FCM permission.
    await FirebaseMessaging.instance.requestPermission();

    // Handle foreground messages.
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().microsecondsSinceEpoch.remainder(1000000),
          channelKey: 'sayr_default',
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: {'trip_id': message.data['trip_id']?.toString() ?? ''},
        ),
      );
    });

    // Handle background messages.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final handler = navigationHandler;
      if (handler != null) {
        handler(FcmPayload.fromMap(message.data));
      }
    });

    await FirebaseMessaging.instance.getToken();
  }

  /// Fetches the current FCM token and registers it using the [NotificationsRepository].
  static Future<void> registerDeviceToken(
    NotificationsRepository repository,
  ) async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final platform =
          Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      if (token != null) {
        unawaited(
          repository.registerPushToken(
            fcmToken: token,
            platform: platform,
          ),
        );
      }

      // Cancel previous listener to prevent duplicates across login cycles.
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        unawaited(
          repository.registerPushToken(
            fcmToken: newToken,
            platform: platform,
          ),
        );
      });
    } catch (e, st) {
      _talker.error(
        'FCM: Failed to register device token',
        e,
        st,
      );
    }
  }

  /// Cancel the token refresh listener and delete the FCM token (call on logout).
  static Future<void> dispose() async {
    if (!_initialized) return;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      _talker.error(
        'FCM: Failed to delete token during dispose',
        e,
        st,
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  var title = notification?.title ?? data['title']?.toString();
  var body = notification?.body ?? data['body']?.toString();

  // Fallback messages for data-only payloads
  if (title == null && body == null) {
    final type = data['type']?.toString();
    final lang = PlatformDispatcher.instance.locale.languageCode;
    final isAr = lang == 'ar';
    if (type == 'chat') {
      title = isAr ? 'رسالة جديدة' : 'New message';
      body = data['message']?.toString() ??
          (isAr ? 'لديك رسالة جديدة' : 'You have a new message');
    } else if (type == 'trip_update') {
      title = isAr ? 'تحديث الرحلة' : 'Trip update';
      body = data['status_text']?.toString() ??
          (isAr ? 'تم تحديث حالة الرحلة' : 'Trip status has been updated');
    }
  }

  if (title != null || body != null) {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'sayr_default',
          channelName: 'إشعارات سير',
          channelDescription: 'إشعارات تطبيق سير للنقل الجامعي',
          defaultColor: const Color(0xFF1E5BFF),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().microsecondsSinceEpoch.remainder(1000000),
        channelKey: 'sayr_default',
        title: title,
        body: body,
        payload: data.map((k, v) => MapEntry(k, v.toString())),
      ),
    );
  }
}
