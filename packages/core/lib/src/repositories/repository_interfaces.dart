import 'package:fpdart/fpdart.dart';

import 'package:sayr_core/src/entities/driver.dart';
import 'package:sayr_core/src/entities/emergency_report.dart';
import 'package:sayr_core/src/entities/message.dart';
import 'package:sayr_core/src/entities/notification.dart';
import 'package:sayr_core/src/entities/payment_info.dart';
import 'package:sayr_core/src/entities/rating.dart';
import 'package:sayr_core/src/entities/route.dart';
import 'package:sayr_core/src/entities/subscription.dart';
import 'package:sayr_core/src/entities/trip.dart';
import 'package:sayr_core/src/entities/user.dart';
import 'package:sayr_core/src/failures/failure.dart';
import 'package:sayr_core/src/fsm/trip_event.dart';
import 'package:sayr_core/src/value_objects/coordinates.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/license_code.dart';

/// Interface for authentication and user management repository.
abstract class AuthRepository {
  /// The currently signed-in user.
  User? get currentUser;

  /// Sign in with email and password.
  Future<Either<Failure, User>> signInWithPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password.
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  /// Sign in with Google.
  Future<Either<Failure, Unit>> signInWithGoogle();

  /// Send a password reset email.
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Update the current user's password after a password recovery link.
  Future<Either<Failure, Unit>> updatePassword(String password);

  /// Update the current user's phone and institution.
  Future<Either<Failure, Unit>> updateProfile({
    required String phone,
    required String institutionId,
  });

  /// Fetch all active institutions.
  Future<Either<Failure, List<({String id, String name, String city})>>>
      getInstitutions();

  /// Sign out.
  Future<void> signOut();

  /// Stream of auth state changes (un-typed to avoid dependency on database client).
  Stream<dynamic> get authStateChanges;
}

/// Interface for route operations repository.
abstract class RouteRepository {
  /// Fetch all active routes.
  Future<Either<Failure, List<Route>>> getActiveRoutes();

  /// Fetch active routes owned by the current driver.
  Future<Either<Failure, List<Route>>> getMyDriverRoutes();

  /// Fetch a route by ID.
  Future<Either<Failure, Route>> getById(RouteId id);

  /// Search routes by query.
  Future<Either<Failure, List<Route>>> search(String query);
}

/// Interface for trip operations repository.
abstract class TripRepository {
  /// Get all active trips for the current user.
  Future<Either<Failure, List<Trip>>> getActiveTrips();

  /// Create a scheduled trip for one of the current driver's routes.
  Future<Either<Failure, Trip>> createTrip({
    required RouteId routeId,
    required DateTime scheduledAt,
  });

  /// Subscribe to a trip's status changes.
  Stream<Trip> watchTrip(TripId tripId);

  /// Get a trip by ID.
  Future<Either<Failure, Trip>> getById(TripId id);

  /// Update trip status.
  Future<Either<Failure, Trip>> updateStatus({
    required TripId tripId,
    required TripEvent event,
    Coordinates? location,
  });

  /// Update only location.
  Future<Either<Failure, Unit>> updateLocation({
    required TripId tripId,
    required double lat,
    required double lng,
  });

  /// Bulk update locations.
  Future<Either<Failure, Unit>> bulkUpdateLocations(
    List<
            ({
              TripId tripId,
              double lat,
              double lng,
            })>
        locations,
  );

  /// Create a Zain Cash payment.
  Future<Either<Failure, PaymentInfo>> createPayment({
    required RouteId routeId,
    required int amount,
    required String currency,
    required String method,
  });

  /// Get payment status.
  Future<Either<Failure, PaymentInfo>> getPaymentStatus(
    String paymentId,
  );

  /// Fetch driver details.
  Future<Either<Failure, Driver>> getDriverById(DriverId id);

  /// Fetch user profile (to load name/avatar/phone for contact).
  Future<Either<Failure, User>> getDriverProfile(UserId userId);

  /// Submit a student rating for a trip.
  Future<Either<Failure, Rating>> submitRating({
    required TripId tripId,
    required DriverId driverId,
    required int rating,
    String? comment,
  });

  /// Get an existing rating for a trip.
  Future<Either<Failure, Rating?>> getTripRating(TripId tripId);
}

/// Interface for subscription operations repository.
abstract class SubscriptionRepository {
  /// Get all subscriptions for the current user.
  Future<Either<Failure, List<Subscription>>> getMySubscriptions();

  /// Get active subscriptions.
  Future<Either<Failure, List<Subscription>>> getActiveSubscriptions();

  /// Cancel a subscription.
  Future<Either<Failure, Unit>> cancel(SubscriptionId id);

  /// Activate a license code (creates a pending subscription).
  Future<Either<Failure, SubscriptionId>> activateLicense(LicenseCode code);
}

/// Interface for chat operations repository.
abstract class ChatRepository {
  /// Get all conversations the current user participates in.
  Future<Either<Failure, List<Conversation>>> getMyConversations();

  /// Subscribe to changes on the user's conversations list.
  Stream<List<Conversation>> watchMyConversations();

  /// Look up an existing conversation or create one.
  Future<Either<Failure, Conversation>> getOrCreateConversation({
    required RouteId routeId,
    required UserId driverUserId,
  });

  /// Get messages for a specific conversation.
  Future<Either<Failure, List<Message>>> getMessages(
    ConversationId conversationId,
  );

  /// Subscribe to messages via Realtime.
  Stream<List<Message>> watchMessages(ConversationId conversationId);

  /// Send a new message.
  Future<Either<Failure, Message>> sendMessage({
    required ConversationId conversationId,
    required String body,
  });

  /// Mark a message as read.
  Future<Either<Failure, Unit>> markAsRead(MessageId messageId);

  /// Get total unread message count.
  Future<Either<Failure, int>> getUnreadCount();
}

/// Interface for in-app notifications repository.
abstract class NotificationsRepository {
  /// Fetch the latest notifications for the current user.
  Future<Either<Failure, List<AppNotification>>> getMyNotifications({
    int limit = 50,
  });

  /// Get the count of unread notifications.
  Future<Either<Failure, int>> getUnreadCount();

  /// Mark a single notification as read.
  Future<Either<Failure, Unit>> markAsRead(NotificationId id);

  /// Mark every unread notification for the current user as read.
  Future<Either<Failure, Unit>> markAllAsRead();

  /// Subscribe to the user's notification stream.
  Stream<List<AppNotification>> watchMyNotifications();

  /// Register (or refresh) the current device's FCM push token.
  Future<Either<Failure, Unit>> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  });
}

/// Interface for emergency (SOS) reports repository.
abstract class EmergencyRepository {
  /// Trigger an SOS alert.
  Future<Either<Failure, EmergencyReport>> triggerEmergency({
    required TripId tripId,
    required RouteId routeId,
    required Coordinates location,
    String? message,
  });

  /// Get the user's most recent active (unresolved) report, if any.
  Future<Either<Failure, EmergencyReport?>> getActiveReport();

  /// Resolve (cancel) an active report.
  Future<Either<Failure, Unit>> resolveReport(EmergencyReportId id);
}
