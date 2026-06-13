//@GeneratedMicroModule;SayrDataPackageModule;package:sayr_data/sayr_data.module.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sayr_core/sayr_core.dart' as _i385;
import 'package:sayr_data/src/datasources/auth_remote_datasource.dart' as _i826;
import 'package:sayr_data/src/datasources/boarding_remote_datasource.dart'
    as _i94;
import 'package:sayr_data/src/datasources/chat_remote_datasource.dart' as _i355;
import 'package:sayr_data/src/datasources/emergency_remote_datasource.dart'
    as _i1068;
import 'package:sayr_data/src/datasources/local_datasource.dart' as _i1015;
import 'package:sayr_data/src/datasources/notification_remote_datasource.dart'
    as _i328;
import 'package:sayr_data/src/datasources/remote_datasource.dart' as _i263;
import 'package:sayr_data/src/datasources/route_remote_datasource.dart'
    as _i675;
import 'package:sayr_data/src/datasources/subscription_remote_datasource.dart'
    as _i635;
import 'package:sayr_data/src/datasources/trip_remote_datasource.dart' as _i140;
import 'package:sayr_data/src/di/data_module.dart' as _i121;
import 'package:sayr_data/src/local/app_database.dart' as _i961;
import 'package:sayr_data/src/local/location_queue_dao.dart' as _i368;
import 'package:sayr_data/src/repositories/auth_repository.dart' as _i479;
import 'package:sayr_data/src/repositories/boarding_repository.dart' as _i388;
import 'package:sayr_data/src/repositories/chat_repository.dart' as _i147;
import 'package:sayr_data/src/repositories/driver_repository.dart' as _i151;
import 'package:sayr_data/src/repositories/emergency_repository.dart' as _i985;
import 'package:sayr_data/src/repositories/notifications_repository.dart'
    as _i57;
import 'package:sayr_data/src/repositories/payment_repository.dart' as _i929;
import 'package:sayr_data/src/repositories/rating_repository.dart' as _i69;
import 'package:sayr_data/src/repositories/route_repository.dart' as _i783;
import 'package:sayr_data/src/repositories/subscription_repository.dart'
    as _i896;
import 'package:sayr_data/src/repositories/trip_repository.dart' as _i549;
import 'package:sayr_data/src/storage/secure_storage.dart' as _i417;
import 'package:sayr_data/src/supabase/supabase_client.dart' as _i583;
import 'package:talker_flutter/talker_flutter.dart' as _i207;

class SayrDataPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final dataModule = _$DataModule();
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => dataModule.secureStorage);
    gh.lazySingleton<_i583.SayrSupabase>(() => dataModule.supabase);
    gh.lazySingleton<_i961.AppDatabase>(() => _i961.AppDatabase());
    gh.lazySingleton<_i368.LocationQueueDao>(
        () => _i368.LocationQueueDao(db: gh<_i961.AppDatabase>()));
    gh.lazySingleton<_i368.TripCacheDao>(
        () => _i368.TripCacheDao(db: gh<_i961.AppDatabase>()));
    gh.lazySingleton<_i368.RouteCacheDao>(
        () => _i368.RouteCacheDao(db: gh<_i961.AppDatabase>()));
    gh.lazySingleton<_i1015.LocalDatasource>(() => _i1015.LocalDatasourceImpl(
          secureStorage: gh<_i417.SecureStorageService>(),
          locationQueueDao: gh<_i368.LocationQueueDao>(),
          tripCacheDao: gh<_i368.TripCacheDao>(),
          routeCacheDao: gh<_i368.RouteCacheDao>(),
        ));
    gh.lazySingleton<_i355.ChatRemoteDatasource>(() =>
        _i355.ChatRemoteDatasourceImpl(supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i94.BoardingRemoteDatasource>(() =>
        _i94.BoardingRemoteDatasourceImpl(supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i140.TripRemoteDatasource>(() =>
        _i140.TripRemoteDatasourceImpl(supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i328.NotificationRemoteDatasource>(() =>
        _i328.NotificationRemoteDatasourceImpl(
            supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i1068.EmergencyRemoteDatasource>(() =>
        _i1068.EmergencyRemoteDatasourceImpl(
            supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i675.RouteRemoteDatasource>(() =>
        _i675.RouteRemoteDatasourceImpl(supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i826.AuthRemoteDatasource>(() =>
        _i826.AuthRemoteDatasourceImpl(supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i635.SubscriptionRemoteDatasource>(() =>
        _i635.SubscriptionRemoteDatasourceImpl(
            supabase: gh<_i583.SayrSupabase>()));
    gh.lazySingleton<_i417.SecureStorageService>(() =>
        _i417.SecureStorageService(storage: gh<_i558.FlutterSecureStorage>()));
    gh.lazySingleton<_i263.RemoteDatasource>(() => _i263.RemoteDatasourceImpl(
          auth: gh<_i826.AuthRemoteDatasource>(),
          chat: gh<_i355.ChatRemoteDatasource>(),
          emergency: gh<_i1068.EmergencyRemoteDatasource>(),
          notifications: gh<_i328.NotificationRemoteDatasource>(),
          routes: gh<_i675.RouteRemoteDatasource>(),
          subscriptions: gh<_i635.SubscriptionRemoteDatasource>(),
          trips: gh<_i140.TripRemoteDatasource>(),
          boarding: gh<_i94.BoardingRemoteDatasource>(),
        ));
    gh.lazySingleton<_i385.ChatRepository>(() => _i147.ChatRepositoryImpl(
          remoteDatasource: gh<_i263.RemoteDatasource>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.RatingRepository>(() => _i69.RatingRepositoryImpl(
          remoteDatasource: gh<_i263.RemoteDatasource>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.PaymentRepository>(() => _i929.PaymentRepositoryImpl(
          remoteDatasource: gh<_i263.RemoteDatasource>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.BoardingRepository>(
        () => _i388.BoardingRepositoryImpl(
              remoteDatasource: gh<_i263.RemoteDatasource>(),
              talker: gh<_i207.Talker>(),
            ));
    gh.lazySingleton<_i385.EmergencyRepository>(
        () => _i985.EmergencyRepositoryImpl(
              remoteDatasource: gh<_i263.RemoteDatasource>(),
              talker: gh<_i207.Talker>(),
            ));
    gh.lazySingleton<_i385.AuthRepository>(() => _i479.AuthRepositoryImpl(
          remoteDatasource: gh<_i263.RemoteDatasource>(),
          localDatasource: gh<_i1015.LocalDatasource>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.TripRepository>(() => _i549.TripRepositoryImpl(
          remoteDatasource: gh<_i263.RemoteDatasource>(),
          localDatasource: gh<_i1015.LocalDatasource>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.RouteRepository>(() => _i783.RouteRepositoryImpl(
          remoteDatasource: gh<_i263.RemoteDatasource>(),
          localDatasource: gh<_i1015.LocalDatasource>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.DriverRepository>(() => _i151.DriverRepositoryImpl(
          remoteDatasource: gh<_i263.RemoteDatasource>(),
          talker: gh<_i207.Talker>(),
        ));
    gh.lazySingleton<_i385.NotificationsRepository>(
        () => _i57.NotificationsRepositoryImpl(
              remoteDatasource: gh<_i263.RemoteDatasource>(),
              talker: gh<_i207.Talker>(),
            ));
    gh.lazySingleton<_i385.SubscriptionRepository>(
        () => _i896.SubscriptionRepositoryImpl(
              remoteDatasource: gh<_i263.RemoteDatasource>(),
              talker: gh<_i207.Talker>(),
            ));
  }
}

class _$DataModule extends _i121.DataModule {}
