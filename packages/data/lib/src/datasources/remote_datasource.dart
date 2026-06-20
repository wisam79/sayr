import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/datasources/auth_remote_datasource.dart';
import 'package:sayr_data/src/datasources/boarding_remote_datasource.dart';
import 'package:sayr_data/src/datasources/chat_remote_datasource.dart';
import 'package:sayr_data/src/datasources/emergency_remote_datasource.dart';
import 'package:sayr_data/src/datasources/notification_remote_datasource.dart';
import 'package:sayr_data/src/datasources/route_remote_datasource.dart';
import 'package:sayr_data/src/datasources/subscription_remote_datasource.dart';
import 'package:sayr_data/src/datasources/trip_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Aggregate remote datasource facade.
///
/// Historically this was a single 868-line god class. It is now a thin
/// facade that delegates to eight focused sub-datasources (one per data
/// domain). The public surface is intentionally identical to the previous
/// implementation so no repository or consumer needs to change.
abstract class RemoteDatasource {
  // Auth
  supabase.User? get currentUser;
  Stream<supabase.AuthState> get authStateChanges;
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });
  Future<bool> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
  Future<Map<String, dynamic>?> fetchCurrentProfile(String userId);
  Future<void> updateProfile({
    required String phone,
    required String institutionId,
  });
  Future<List<Map<String, dynamic>>> getInstitutions();

  // Chat
  Future<List<Map<String, dynamic>>> getMyConversations(String currentUserId);
  Stream<List<Map<String, dynamic>>> watchMyConversations(String currentUserId);
  Future<Map<String, dynamic>?> getConversation({
    required String routeId,
    required String studentId,
  });
  Future<Map<String, dynamic>> createConversation({
    required String routeId,
    required String studentId,
    required String driverUserId,
  });
  Future<List<Map<String, dynamic>>> getMessages(String conversationId);
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId);
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  });
  Future<void> markMessageAsRead({
    required String messageId,
    required String readAt,
  });
  Future<int> getUnreadChatCount();
  Future<void> updateConversationPreview({
    required String conversationId,
    required String body,
    required String updatedAt,
  });

  // Emergency
  Future<String> triggerEmergency({
    required String tripId,
    required String routeId,
    required String studentId,
    required String description,
    double? lat,
    double? lng,
  });
  Future<Map<String, dynamic>?> getActiveEmergencyReport(String userId);
  Future<void> resolveEmergencyReport({
    required String id,
    required String resolvedAt,
  });

  // Notifications
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String userId,
    int limit = 50,
  });
  Future<int> getUnreadNotificationCount(String userId);
  Future<void> markNotificationAsRead({
    required String id,
    required String readAt,
  });
  Future<void> markAllNotificationsAsRead({
    required String userId,
    required String readAt,
  });
  Stream<List<Map<String, dynamic>>> watchMyNotifications(String userId);
  Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  });

  /// Deactivate all push tokens for the current user (called on logout).
  Future<void> deactivatePushTokens();

  // Routes
  Future<List<Map<String, dynamic>>> getActiveRoutes();
  Future<List<Map<String, dynamic>>> getMyDriverRoutes();
  Future<Map<String, dynamic>?> getRouteById(String id);
  Future<List<Map<String, dynamic>>> searchRoutes(String query);

  // Subscriptions
  Future<List<Map<String, dynamic>>> getMySubscriptions(String studentId);
  Future<void> cancelSubscription(String subscriptionId);
  Future<String> activateLicense(String code);
  Future<Map<String, dynamic>> getLicenseDetails(String code);

  // Trips
  Future<List<Map<String, dynamic>>> getActiveTrips();
  Future<String> createTrip({
    required String routeId,
    required DateTime scheduledAt,
  });
  Stream<List<Map<String, dynamic>>> watchTrip(String tripId);
  Future<Map<String, dynamic>?> getTripById(String id);
  Future<Map<String, dynamic>> updateTripStatus({
    required String tripId,
    required String newStatus,
    double? lat,
    double? lng,
  });
  Future<void> updateTripLocation({
    required String tripId,
    required double lat,
    required double lng,
  });
  Future<void> updateTripBleOtp({
    required String tripId,
    required String otp,
    required String expiresAt,
  });
  Future<void> bulkUpdateTripLocations(List<Map<String, dynamic>> locations);
  Future<Map<String, dynamic>> createPayment({
    required String routeId,
    required int amount,
    required String currency,
    required String method,
  });
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId);
  Future<List<Map<String, dynamic>>> getPendingPayments();
  Future<Map<String, dynamic>?> getDriverById(String driverId);
  Future<Map<String, dynamic>> submitRating({
    required String tripId,
    required String driverId,
    required String studentId,
    required int rating,
    String? comment,
  });
  Future<Map<String, dynamic>?> getTripRating({
    required String tripId,
    required String studentId,
  });

  // Boarding (QR + proximity)
  Future<String?> getActiveTripForSubscription();
  Future<({String token, DateTime expiresAt})> generateBoardingToken(
    String tripId,
  );
  Future<Map<String, dynamic>> validateBoarding({
    required String token,
    required String tripId,
    double? lat,
    double? lng,
  });
  Future<List<Map<String, dynamic>>> getTripPassengers(String tripId);
  Stream<List<Map<String, dynamic>>> watchTripPassengers(String tripId);
  Future<Map<String, dynamic>> validateBoardingViaProximity({
    required String tripId,
    required String otp,
    double? lat,
    double? lng,
  });
}

/// Facade implementation that delegates each call to the corresponding
/// focused sub-datasource. Kept thin on purpose — all real logic lives
/// in the eight `*_remote_datasource.dart` files in this directory.
@LazySingleton(as: RemoteDatasource)
class RemoteDatasourceImpl implements RemoteDatasource {
  RemoteDatasourceImpl({
    required AuthRemoteDatasource auth,
    required ChatRemoteDatasource chat,
    required EmergencyRemoteDatasource emergency,
    required NotificationRemoteDatasource notifications,
    required RouteRemoteDatasource routes,
    required SubscriptionRemoteDatasource subscriptions,
    required TripRemoteDatasource trips,
    required BoardingRemoteDatasource boarding,
  })  : _auth = auth,
        _chat = chat,
        _emergency = emergency,
        _notifications = notifications,
        _routes = routes,
        _subscriptions = subscriptions,
        _trips = trips,
        _boarding = boarding;

  final AuthRemoteDatasource _auth;
  final ChatRemoteDatasource _chat;
  final EmergencyRemoteDatasource _emergency;
  final NotificationRemoteDatasource _notifications;
  final RouteRemoteDatasource _routes;
  final SubscriptionRemoteDatasource _subscriptions;
  final TripRemoteDatasource _trips;
  final BoardingRemoteDatasource _boarding;

  // ---- Auth ---------------------------------------------------------------

  @override
  supabase.User? get currentUser => _auth.currentUser;

  @override
  Stream<supabase.AuthState> get authStateChanges => _auth.authStateChanges;

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithPassword(email: email, password: password);

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) =>
      _auth.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

  @override
  Future<bool> signInWithGoogle() => _auth.signInWithGoogle();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email);

  @override
  Future<void> updatePassword(String password) =>
      _auth.updatePassword(password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<Map<String, dynamic>?> fetchCurrentProfile(String userId) =>
      _auth.fetchCurrentProfile(userId);

  @override
  Future<void> updateProfile({
    required String phone,
    required String institutionId,
  }) =>
      _auth.updateProfile(
        phone: phone,
        institutionId: institutionId,
      );

  @override
  Future<List<Map<String, dynamic>>> getInstitutions() =>
      _auth.getInstitutions();

  // ---- Chat ---------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getMyConversations(
    String currentUserId,
  ) =>
      _chat.getMyConversations(currentUserId);

  @override
  Stream<List<Map<String, dynamic>>> watchMyConversations(
    String currentUserId,
  ) =>
      _chat.watchMyConversations(currentUserId);

  @override
  Future<Map<String, dynamic>?> getConversation({
    required String routeId,
    required String studentId,
  }) =>
      _chat.getConversation(routeId: routeId, studentId: studentId);

  @override
  Future<Map<String, dynamic>> createConversation({
    required String routeId,
    required String studentId,
    required String driverUserId,
  }) =>
      _chat.createConversation(
        routeId: routeId,
        studentId: studentId,
        driverUserId: driverUserId,
      );

  @override
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) =>
      _chat.getMessages(conversationId);

  @override
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) =>
      _chat.watchMessages(conversationId);

  @override
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
  }) =>
      _chat.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        body: body,
      );

  @override
  Future<void> markMessageAsRead({
    required String messageId,
    required String readAt,
  }) =>
      _chat.markMessageAsRead(messageId: messageId, readAt: readAt);

  @override
  Future<int> getUnreadChatCount() => _chat.getUnreadChatCount();

  @override
  Future<void> updateConversationPreview({
    required String conversationId,
    required String body,
    required String updatedAt,
  }) =>
      _chat.updateConversationPreview(
        conversationId: conversationId,
        body: body,
        updatedAt: updatedAt,
      );

  // ---- Emergency ----------------------------------------------------------

  @override
  Future<String> triggerEmergency({
    required String tripId,
    required String routeId,
    required String studentId,
    required String description,
    double? lat,
    double? lng,
  }) =>
      _emergency.triggerEmergency(
        tripId: tripId,
        routeId: routeId,
        studentId: studentId,
        lat: lat,
        lng: lng,
        description: description,
      );

  @override
  Future<Map<String, dynamic>?> getActiveEmergencyReport(String userId) =>
      _emergency.getActiveEmergencyReport(userId);

  @override
  Future<void> resolveEmergencyReport({
    required String id,
    required String resolvedAt,
  }) =>
      _emergency.resolveEmergencyReport(id: id, resolvedAt: resolvedAt);

  // ---- Notifications ------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String userId,
    int limit = 50,
  }) =>
      _notifications.getMyNotifications(userId: userId, limit: limit);

  @override
  Future<int> getUnreadNotificationCount(String userId) =>
      _notifications.getUnreadNotificationCount(userId);

  @override
  Future<void> markNotificationAsRead({
    required String id,
    required String readAt,
  }) =>
      _notifications.markNotificationAsRead(id: id, readAt: readAt);

  @override
  Future<void> markAllNotificationsAsRead({
    required String userId,
    required String readAt,
  }) =>
      _notifications.markAllNotificationsAsRead(
        userId: userId,
        readAt: readAt,
      );

  @override
  Stream<List<Map<String, dynamic>>> watchMyNotifications(String userId) =>
      _notifications.watchMyNotifications(userId);

  @override
  Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  }) =>
      _notifications.registerPushToken(
        fcmToken: fcmToken,
        platform: platform,
        deviceId: deviceId,
      );

  @override
  Future<void> deactivatePushTokens() => _notifications.deactivatePushTokens();

  // ---- Routes -------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getActiveRoutes() =>
      _routes.getActiveRoutes();

  @override
  Future<List<Map<String, dynamic>>> getMyDriverRoutes() =>
      _routes.getMyDriverRoutes();

  @override
  Future<Map<String, dynamic>?> getRouteById(String id) =>
      _routes.getRouteById(id);

  @override
  Future<List<Map<String, dynamic>>> searchRoutes(String query) =>
      _routes.searchRoutes(query);

  // ---- Subscriptions ------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getMySubscriptions(String studentId) =>
      _subscriptions.getMySubscriptions(studentId);

  @override
  Future<void> cancelSubscription(String subscriptionId) =>
      _subscriptions.cancelSubscription(subscriptionId);

  @override
  Future<String> activateLicense(String code) =>
      _subscriptions.activateLicense(code);

  @override
  Future<Map<String, dynamic>> getLicenseDetails(String code) =>
      _subscriptions.getLicenseDetails(code);

  // ---- Trips --------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getActiveTrips() =>
      _trips.getActiveTrips();

  @override
  Future<String> createTrip({
    required String routeId,
    required DateTime scheduledAt,
  }) =>
      _trips.createTrip(routeId: routeId, scheduledAt: scheduledAt);

  @override
  Stream<List<Map<String, dynamic>>> watchTrip(String tripId) =>
      _trips.watchTrip(tripId);

  @override
  Future<Map<String, dynamic>?> getTripById(String id) =>
      _trips.getTripById(id);

  @override
  Future<Map<String, dynamic>> updateTripStatus({
    required String tripId,
    required String newStatus,
    double? lat,
    double? lng,
  }) =>
      _trips.updateTripStatus(
        tripId: tripId,
        newStatus: newStatus,
        lat: lat,
        lng: lng,
      );

  @override
  Future<void> updateTripLocation({
    required String tripId,
    required double lat,
    required double lng,
  }) =>
      _trips.updateTripLocation(
        tripId: tripId,
        lat: lat,
        lng: lng,
      );

  @override
  Future<void> updateTripBleOtp({
    required String tripId,
    required String otp,
    required String expiresAt,
  }) =>
      _trips.updateTripBleOtp(
        tripId: tripId,
        otp: otp,
        expiresAt: expiresAt,
      );

  @override
  Future<void> bulkUpdateTripLocations(
    List<Map<String, dynamic>> locations,
  ) =>
      _trips.bulkUpdateTripLocations(locations);

  @override
  Future<Map<String, dynamic>> createPayment({
    required String routeId,
    required int amount,
    required String currency,
    required String method,
  }) =>
      _trips.createPayment(
        routeId: routeId,
        amount: amount,
        currency: currency,
        method: method,
      );

  @override
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId) =>
      _trips.getPaymentStatus(paymentId);

  @override
  Future<List<Map<String, dynamic>>> getPendingPayments() =>
      _trips.getPendingPayments();

  @override
  Future<Map<String, dynamic>?> getDriverById(String driverId) =>
      _trips.getDriverById(driverId);

  @override
  Future<Map<String, dynamic>> submitRating({
    required String tripId,
    required String driverId,
    required String studentId,
    required int rating,
    String? comment,
  }) =>
      _trips.submitRating(
        tripId: tripId,
        driverId: driverId,
        studentId: studentId,
        rating: rating,
        comment: comment,
      );

  @override
  Future<Map<String, dynamic>?> getTripRating({
    required String tripId,
    required String studentId,
  }) =>
      _trips.getTripRating(tripId: tripId, studentId: studentId);

  // ---- Boarding -----------------------------------------------------------

  @override
  Future<String?> getActiveTripForSubscription() =>
      _boarding.getActiveTripForSubscription();

  @override
  Future<({String token, DateTime expiresAt})> generateBoardingToken(
    String tripId,
  ) =>
      _boarding.generateBoardingToken(tripId);

  @override
  Future<Map<String, dynamic>> validateBoarding({
    required String token,
    required String tripId,
    double? lat,
    double? lng,
  }) =>
      _boarding.validateBoarding(
        token: token,
        tripId: tripId,
        lat: lat,
        lng: lng,
      );

  @override
  Future<List<Map<String, dynamic>>> getTripPassengers(String tripId) =>
      _boarding.getTripPassengers(tripId);

  @override
  Stream<List<Map<String, dynamic>>> watchTripPassengers(String tripId) =>
      _boarding.watchTripPassengers(tripId);

  @override
  Future<Map<String, dynamic>> validateBoardingViaProximity({
    required String tripId,
    required String otp,
    double? lat,
    double? lng,
  }) =>
      _boarding.validateBoardingViaProximity(
        tripId: tripId,
        otp: otp,
        lat: lat,
        lng: lng,
      );
}
