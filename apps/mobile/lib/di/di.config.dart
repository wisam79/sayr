// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sayr_core/sayr_core.dart' as _i385;
import 'package:sayr_data/sayr_data.dart' as _i773;
import 'package:sayr_mobile/core/services/osrm_service.dart' as _i105;
import 'package:sayr_mobile/di/data_repositories_module.dart' as _i1014;
import 'package:sayr_mobile/routing/app_router.dart' as _i290;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final dataRepositoriesModule = _$DataRepositoriesModule();
    gh.lazySingleton<_i105.OsrmService>(() => _i105.OsrmService());
    gh.lazySingleton<_i773.RemoteDatasource>(
        () => dataRepositoriesModule.remoteDatasource);
    gh.lazySingleton<_i773.AppDatabase>(
        () => dataRepositoriesModule.appDatabase);
    gh.lazySingleton<_i773.SecureStorageService>(
        () => dataRepositoriesModule.secureStorageService);
    gh.lazySingleton<_i290.AppRouter>(() => _i290.AppRouter());
    gh.lazySingleton<_i385.SubscriptionRepository>(() => dataRepositoriesModule
        .subscriptionRepository(gh<_i773.RemoteDatasource>()));
    gh.lazySingleton<_i385.ChatRepository>(() =>
        dataRepositoriesModule.chatRepository(gh<_i773.RemoteDatasource>()));
    gh.lazySingleton<_i385.NotificationsRepository>(() => dataRepositoriesModule
        .notificationsRepository(gh<_i773.RemoteDatasource>()));
    gh.lazySingleton<_i385.EmergencyRepository>(() => dataRepositoriesModule
        .emergencyRepository(gh<_i773.RemoteDatasource>()));
    gh.lazySingleton<_i773.LocalDatasource>(
        () => dataRepositoriesModule.localDatasource(gh<_i773.AppDatabase>()));
    gh.lazySingleton<_i385.AuthRepository>(
        () => dataRepositoriesModule.authRepository(
              gh<_i773.RemoteDatasource>(),
              gh<_i773.LocalDatasource>(),
            ));
    gh.lazySingleton<_i385.RouteRepository>(
        () => dataRepositoriesModule.routeRepository(
              gh<_i773.RemoteDatasource>(),
              gh<_i773.LocalDatasource>(),
            ));
    gh.lazySingleton<_i385.TripRepository>(
        () => dataRepositoriesModule.tripRepository(
              gh<_i773.RemoteDatasource>(),
              gh<_i773.LocalDatasource>(),
            ));
    return this;
  }
}

class _$DataRepositoriesModule extends _i1014.DataRepositoriesModule {}
