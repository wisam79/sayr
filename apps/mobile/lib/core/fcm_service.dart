import 'dart:async';

import 'dart:io' show Platform;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:logger/logger.dart';

import 'package:sayr_mobile/core/firebase_config.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';

/// Firebase Cloud Messaging service using `awesome_notifications` for
/// cross-platform local notifications (channels, actions, scheduling built-in).
class FcmService {
  FcmService._();

  static final Logger _logger = Logger();

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Optional navigation callback. The callback receives the FCM `data`
  /// payload (e.g. a `trip_id`, `conversation_id`, or `route_id`). Called
  /// from the app shell after the router is ready.
  static void Function(Map<String, dynamic> data)? navigationHandler;

  /// Initialize FCM + awesome_notifications.
  static Future<void> init() async {
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
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.topicAllStudents);
  }

  /// Subscribe to all-drivers topic.
  static Future<void> subscribeToAllDrivers() async {
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.topicAllDrivers);
  }

  /// Subscribe to a specific route topic.
  static Future<void> subscribeToRoute(String routeId) async {
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.routeTopic(routeId));
  }

  /// Unsubscribe from a route topic.
  static Future<void> unsubscribeFromRoute(String routeId) async {
    await FirebaseMessaging.instance
        .unsubscribeFromTopic(FirebaseConfig.routeTopic(routeId));
  }

  /// Subscribe to a specific trip topic.
  static Future<void> subscribeToTrip(String tripId) async {
    await FirebaseMessaging.instance
        .subscribeToTopic(FirebaseConfig.tripTopic(tripId));
  }

  /// Unsubscribe from a trip topic.
  static Future<void> unsubscribeFromTrip(String tripId) async {
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
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
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
      tripId: message.data['trip_id'] as String?,
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final handler = navigationHandler;
    if (handler == null) {
      return;
    }
    handler(Map<String, dynamic>.from(message.data));
  }

  /// Fetches the current FCM token and registers it using the [NotificationsBloc].
  static Future<void> registerDeviceToken(NotificationsBloc bloc) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final platform =
            Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
        bloc.add(
          NotificationRegisterTokenRequested(
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
        bloc.add(
          NotificationRegisterTokenRequested(
            fcmToken: newToken,
            platform: platform,
          ),
        );
      });
    } catch (e, st) {
      _logger.e(
        'FCM: Failed to retrieve or register token',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Cancel the token refresh listener and delete the FCM token (call on logout)
  /// to unsubscribe from all topics.
  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      _logger.e(
        'FCM: Failed to delete token during dispose',
        error: e,
        stackTrace: st,
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  var title = notification?.title ?? data['title'] as String?;
  var body = notification?.body ?? data['body'] as String?;

  // Fallback messages for data-only payloads
  if (title == null && body == null) {
    final type = data['type'] as String?;
    if (type == 'chat') {
      title = 'رسالة جديدة';
      body = data['message'] as String? ?? 'لديك رسالة جديدة';
    } else if (type == 'trip_update') {
      title = 'تحديث الرحلة';
      body = data['status_text'] as String? ?? 'تم تحديث حالة الرحلة';
    }
  }

  if (title != null || body != null) {
    // Initialize AwesomeNotifications in the background isolate
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
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        channelKey: 'sayr_default',
        title: title,
        body: body,
        payload: data.map((k, v) => MapEntry(k, v.toString())),
      ),
    );
  }
}
