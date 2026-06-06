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
  RemoteDatasource get remoteDatasource => RemoteDatasourceImpl();

  /// Provides the singleton instance of [LocalDatasource].
  @lazySingleton
  LocalDatasource get localDatasource => LocalDatasourceImpl();

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

  /// Provides the singleton instance of [SecureStorageService].
  @lazySingleton
  SecureStorageService get secureStorageService => SecureStorageService();
}
