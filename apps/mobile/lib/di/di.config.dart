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
import 'package:sayr_data/sayr_data.module.dart' as _i59;
import 'package:sayr_mobile/core/services/ble_beacon_service.dart' as _i385;
import 'package:sayr_mobile/core/talker_service.dart' as _i754;
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
    gh.lazySingleton<_i385.BleBeaconService>(() => _i385.BleBeaconService());
    gh.lazySingleton<_i207.Talker>(() => talkerModule.talker);
    return this;
  }
}

class _$TalkerModule extends _i754.TalkerModule {}
