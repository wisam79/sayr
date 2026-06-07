import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

/// Bridges the data package's repositories into this app's DI graph.
///
/// `injectable` only scans the current package for `@injectable`-annotated
/// classes, so repositories defined in `sayr_data` are re-exported here
/// via this module.
@module
abstract class DataRepositoriesModule {
  /// Provides the singleton instance of [RemoteDatasource].
  @lazySingleton
  RemoteDatasource remoteDatasource(
    AuthRemoteDatasource auth,
    ChatRemoteDatasource chat,
    EmergencyRemoteDatasource emergency,
    NotificationRemoteDatasource notifications,
    RouteRemoteDatasource routes,
    SubscriptionRemoteDatasource subscriptions,
    TripRemoteDatasource trips,
    BoardingRemoteDatasource boarding,
  ) =>
      RemoteDatasourceImpl(
        auth: auth,
        chat: chat,
        emergency: emergency,
        notifications: notifications,
        routes: routes,
        subscriptions: subscriptions,
        trips: trips,
        boarding: boarding,
      );

  /// Provides the singleton instance of [AppDatabase].
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  /// Provides the singleton instance of [LocalDatasource].
  @lazySingleton
  LocalDatasource localDatasource(AppDatabase db) => LocalDatasourceImpl(
        locationQueueDao: LocationQueueDao(db: db),
        tripCacheDao: TripCacheDao(db: db),
        routeCacheDao: RouteCacheDao(db: db),
      );

  /// Provides the singleton instance of [AuthRepository].
  @lazySingleton
  AuthRepository authRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      AuthRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  /// Provides the singleton instance of [RouteRepository].
  @lazySingleton
  RouteRepository routeRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      RouteRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  /// Provides the singleton instance of [TripRepository].
  @lazySingleton
  TripRepository tripRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      TripRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  /// Provides the singleton instance of [SubscriptionRepository].
  @lazySingleton
  SubscriptionRepository subscriptionRepository(
    RemoteDatasource remote,
  ) =>
      SubscriptionRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [ChatRepository].
  @lazySingleton
  ChatRepository chatRepository(
    RemoteDatasource remote,
  ) =>
      ChatRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [NotificationsRepository].
  @lazySingleton
  NotificationsRepository notificationsRepository(
    RemoteDatasource remote,
  ) =>
      NotificationsRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [EmergencyRepository].
  @lazySingleton
  EmergencyRepository emergencyRepository(
    RemoteDatasource remote,
  ) =>
      EmergencyRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [BoardingRepository].
  @lazySingleton
  BoardingRepository boardingRepository(
    RemoteDatasource remote,
  ) =>
      BoardingRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [PaymentRepository].
  @lazySingleton
  PaymentRepository paymentRepository(
    RemoteDatasource remote,
  ) =>
      PaymentRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [DriverRepository].
  @lazySingleton
  DriverRepository driverRepository(
    RemoteDatasource remote,
  ) =>
      DriverRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [RatingRepository].
  @lazySingleton
  RatingRepository ratingRepository(
    RemoteDatasource remote,
  ) =>
      RatingRepositoryImpl(
        remoteDatasource: remote,
      );

  /// Provides the singleton instance of [SecureStorageService].
  @lazySingleton
  SecureStorageService get secureStorageService => SecureStorageService();
}
