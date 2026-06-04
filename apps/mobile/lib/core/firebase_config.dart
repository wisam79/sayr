/// Firebase configuration for Sayr.
///
/// Android: google-services.json (configured in Android Studio)
/// iOS: GoogleService-Info.plist
///
/// Setup steps:
/// 1. Create Firebase project at https://console.firebase.google.com
/// 2. Add Android app (com.sayr.app) → download google-services.json
/// 3. Add iOS app (com.sayr.app) → download GoogleService-Info.plist
/// 4. Run `flutterfire configure` to generate firebase_options.dart
/// 5. Set FCM_SERVER_KEY in .env for push notifications
class FirebaseConfig {
  const FirebaseConfig._();

  /// FCM topic for broadcast notifications to all students.
  static const topicAllStudents = 'all_students';

  /// FCM topic for broadcast to all drivers.
  static const topicAllDrivers = 'all_drivers';

  /// FCM topic for a specific route updates.
  static String routeTopic(String routeId) => 'route_$routeId';

  /// FCM topic for a specific trip updates.
  static String tripTopic(String tripId) => 'trip_$tripId';

  /// FCM topic for admin notifications.
  static const topicAdmins = 'admins';
}
