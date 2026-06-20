import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_data/sayr_data.module.dart';
import 'package:sayr_mobile/di/di.config.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Service Locator for dependency injection.
///
/// Repositories, services, and other dependencies are registered via
/// `@injectable` annotations and auto-generated. See `app_router.dart`
/// for the router.
final GetIt sl = GetIt.instance;

/// Initialize the DI container using [initDependencies].
///
/// Must be called after `SayrSupabase.instance.init()`.
@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(SayrDataPackageModule),
  ],
)
Future<void> initDependencies() async => sl.init();

/// Initialize a lightweight DI container for background isolates.
///
/// Registers only the required data layer and repository classes to prevent
/// loading UI-bound or configuration-heavy singletons in background processes.
Future<void> initBackgroundDependencies() async {
  if (sl.isRegistered<Talker>()) return;

  // Talker for logging
  final talker = Talker();
  sl.registerSingleton<Talker>(talker);

  // Local Datasource (Drift + Secure Storage)
  final localDatasource = LocalDatasourceImpl();
  sl.registerSingleton<LocalDatasource>(localDatasource);

  // Remote sub-datasources (Supabase API integrations)
  final authRemote = AuthRemoteDatasourceImpl();
  final chatRemote = ChatRemoteDatasourceImpl();
  final emergencyRemote = EmergencyRemoteDatasourceImpl();
  final notificationsRemote = NotificationRemoteDatasourceImpl();
  final routesRemote = RouteRemoteDatasourceImpl();
  final subscriptionsRemote = SubscriptionRemoteDatasourceImpl();
  final tripsRemote = TripRemoteDatasourceImpl();
  final boardingRemote = BoardingRemoteDatasourceImpl();

  // Remote Datasource facade
  final remoteDatasource = RemoteDatasourceImpl(
    auth: authRemote,
    chat: chatRemote,
    emergency: emergencyRemote,
    notifications: notificationsRemote,
    routes: routesRemote,
    subscriptions: subscriptionsRemote,
    trips: tripsRemote,
    boarding: boardingRemote,
  );
  sl.registerSingleton<RemoteDatasource>(remoteDatasource);

  // Repositories
  final tripRepository = TripRepositoryImpl(
    remoteDatasource: remoteDatasource,
    localDatasource: localDatasource,
    talker: talker,
  );
  sl.registerSingleton<TripRepository>(tripRepository);
}
