// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sayr_core/sayr_core.dart' as _i385;
import 'package:sayr_data/sayr_data.dart' as _i773;
import 'package:sayr_data/sayr_data.module.dart' as _i59;
import 'package:sayr_mobile/core/offline_sync_service.dart' as _i931;
import 'package:sayr_mobile/core/services/ble_beacon_service.dart' as _i385;
import 'package:sayr_mobile/core/talker_service.dart' as _i754;
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart'
    as _i258;
import 'package:talker_flutter/talker_flutter.dart' as _i207;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    await _i59.SayrDataPackageModule().init(gh);
    final talkerModule = _$TalkerModule();
    gh.lazySingleton<_i207.Talker>(() => talkerModule.talker);
    gh.lazySingleton<_i258.TrackingBloc>(() => _i258.TrackingBloc(
          tripRepository: gh<_i385.TripRepository>(),
          authRepository: gh<_i385.AuthRepository>(),
          driverLocationService: gh<_i385.LocationService>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.BleBeaconService>(
      () => _i385.BleBeaconService(gh<_i207.Talker>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i931.OfflineSyncService>(() => _i931.OfflineSyncService(
          localDatasource: gh<_i773.LocalDatasource>(),
          tripRepository: gh<_i385.TripRepository>(),
          talker: gh<_i207.Talker>(),
          connectivity: gh<_i895.Connectivity>(),
        ));
    return this;
  }
}

class _$TalkerModule extends _i754.TalkerModule {}
