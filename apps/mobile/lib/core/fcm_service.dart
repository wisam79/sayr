import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/firebase_config.dart';
import 'package:sayr_mobile/core/models/fcm_payload.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Firebase Cloud Messaging service using `awesome_notifications` for
/// cross-platform local notifications (channels, actions, scheduling built-in).
class FcmService {
  FcmService._();

  static Talker get _talker => sl<Talker>();

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static int _notificationCounter = 0;

  /// Generates a collision-resistant notification ID.
  static int generateNotificationId({String? title, String? body}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final hash = ((title?.hashCode ?? 0) ^ (body?.hashCode ?? 0)).abs();
    _notificationCounter = (_notificationCounter + 1) % 1000;
    return (now + hash + _notificationCounter).remainder(2147483647);
  }

  /// Optional navigation callback. The callback receives the parsed type-safe
  /// [FcmPayload]. Called from the app shell after the router is ready.
  static void Function(FcmPayload payload)? navigationHandler;

  /// Initialize FCM + awesome_notifications.
  static Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    if (_initialized) return;
    _initialized = true;

    // NOTE: Channel names/descriptions are Arabic-only because they are set
    // during init() before the widget tree is available. Android notification
    // channels are visible in system settings and can't use Flutter l10n here.
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
        NotificationChannel(
          channelKey: 'sayr_trip',
          channelName: 'تحديثات الرحلات',
          channelDescription: 'تحديثات حالة الرحلة الحالية',
          importance: NotificationImportance.High,
        ),
      ],
    );

    // Request notification permission.
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // FCM permission.
    await FirebaseMessaging.instance.requestPermission();

    // FCM permission granted — proceed.

    // Handle foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    await FirebaseMessaging.instance.getToken();
  }

  /// Subscribe to all-students topic.
  static Future<void> subscribeToAllStudents() async {
    if (!_initialized) return;
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.topicAllStudents);
  }

  /// Subscribe to all-drivers topic.
  static Future<void> subscribeToAllDrivers() async {
    if (!_initialized) return;
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.topicAllDrivers);
  }

  /// Subscribe to a specific route topic.
  static Future<void> subscribeToRoute(String routeId) async {
    if (!_initialized) return;
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.routeTopic(routeId));
  }

  /// Unsubscribe from a route topic.
  static Future<void> unsubscribeFromRoute(String routeId) async {
    if (!_initialized) return;
    await FirebaseMessaging.instance
        .unsubscribeFromTopic(FirebaseConfig.routeTopic(routeId));
  }

  /// Subscribe to a specific trip topic.
  static Future<void> subscribeToTrip(String tripId) async {
    if (!_initialized) return;
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.tripTopic(tripId));
  }

  /// Unsubscribe from a trip topic.
  static Future<void> unsubscribeFromTrip(String tripId) async {
    if (!_initialized) return;
    await FirebaseMessaging.instance
        .unsubscribeFromTopic(FirebaseConfig.tripTopic(tripId));
  }

  /// Show a local notification (used by FCM foreground handler).
  static Future<void> showLocal({
    required String title,
    required String body,
    String? tripId,
    String channelKey = 'sayr_default',
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: generateNotificationId(title: title, body: body),
        channelKey: channelKey,
        title: title,
        body: body,
        payload: {'trip_id': tripId ?? ''},
      ),
    );
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await showLocal(
      title: notification.title ?? '',
      body: notification.body ?? '',
      tripId: message.data['trip_id']?.toString(),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final handler = navigationHandler;
    if (handler == null) {
      return;
    }
    handler(FcmPayload.fromMap(message.data));
  }

  /// Fetches the current FCM token and registers it using the [NotificationsRepository].
  static Future<void> registerDeviceToken(
    NotificationsRepository repository,
  ) async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final platform =
            Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
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
        final platform =
            Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
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

  /// Cancel the token refresh listener and delete the FCM token (call on logout)
  /// to unsubscribe from all topics.
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

bool _backgroundNotificationsInitialized = false;

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
    // Initialize AwesomeNotifications in the background isolate only once
    if (!_backgroundNotificationsInitialized) {
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
      _backgroundNotificationsInitialized = true;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: FcmService.generateNotificationId(title: title, body: body),
        channelKey: 'sayr_default',
        title: title,
        body: body,
        payload: data.map((k, v) => MapEntry(k, v.toString())),
      ),
    );
  }
}
