import 'package:injectable/injectable.dart';
import 'package:sayr_data/sayr_data.dart';

/// Bridges the data package's repositories into this app's DI graph.
///
/// `injectable` only scans the current package for `@injectable`-annotated
/// classes, so repositories defined in `sayr_data` are re-exported here
/// via this module.
@module
abstract class DataRepositoriesModule {
  @lazySingleton
  AuthRepository get authRepository => AuthRepository();

  @lazySingleton
  RouteRepository get routeRepository => RouteRepository();

  @lazySingleton
  TripRepository get tripRepository => TripRepository();

  @lazySingleton
  SubscriptionRepository get subscriptionRepository => SubscriptionRepository();

  @lazySingleton
  ChatRepository get chatRepository => ChatRepository();

  @lazySingleton
  NotificationsRepository get notificationsRepository =>
      NotificationsRepository();

  @lazySingleton
  EmergencyRepository get emergencyRepository => EmergencyRepository();

  @lazySingleton
  SecureStorageService get secureStorageService => SecureStorageService();
}
