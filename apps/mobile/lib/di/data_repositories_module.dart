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
  @lazySingleton
  RemoteDatasource get remoteDatasource => RemoteDatasourceImpl();

  @lazySingleton
  LocalDatasource get localDatasource => LocalDatasourceImpl();

  @lazySingleton
  AuthRepository authRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      AuthRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  @lazySingleton
  RouteRepository routeRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      RouteRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  @lazySingleton
  TripRepository tripRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      TripRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  @lazySingleton
  SubscriptionRepository subscriptionRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      SubscriptionRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  @lazySingleton
  ChatRepository chatRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      ChatRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  @lazySingleton
  NotificationsRepository notificationsRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      NotificationsRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  @lazySingleton
  EmergencyRepository emergencyRepository(
    RemoteDatasource remote,
    LocalDatasource local,
  ) =>
      EmergencyRepositoryImpl(
        remoteDatasource: remote,
        localDatasource: local,
      );

  @lazySingleton
  SecureStorageService get secureStorageService => SecureStorageService();
}
