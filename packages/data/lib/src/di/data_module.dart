import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';

/// Module to provide external/custom singletons for packages/data's DI.
@module
abstract class DataModule {
  /// Provides the singleton [FlutterSecureStorage].
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );

  /// Provides the singleton [SayrSupabase].
  @lazySingleton
  SayrSupabase get supabase => SayrSupabase.instance;
}
