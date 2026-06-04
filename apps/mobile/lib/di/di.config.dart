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
import 'package:sayr_data/sayr_data.dart' as _i773;
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
    gh.lazySingleton<_i773.AuthRepository>(
        () => dataRepositoriesModule.authRepository);
    gh.lazySingleton<_i773.RouteRepository>(
        () => dataRepositoriesModule.routeRepository);
    gh.lazySingleton<_i773.TripRepository>(
        () => dataRepositoriesModule.tripRepository);
    gh.lazySingleton<_i773.SubscriptionRepository>(
        () => dataRepositoriesModule.subscriptionRepository);
    gh.lazySingleton<_i773.ChatRepository>(
        () => dataRepositoriesModule.chatRepository);
    gh.lazySingleton<_i773.NotificationsRepository>(
        () => dataRepositoriesModule.notificationsRepository);
    gh.lazySingleton<_i773.EmergencyRepository>(
        () => dataRepositoriesModule.emergencyRepository);
    gh.lazySingleton<_i773.SecureStorageService>(
        () => dataRepositoriesModule.secureStorageService);
    gh.lazySingleton<_i290.AppRouter>(() => _i290.AppRouter());
    return this;
  }
}

class _$DataRepositoriesModule extends _i1014.DataRepositoriesModule {}
