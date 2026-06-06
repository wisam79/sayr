import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:sayr_mobile/di/di.config.dart';

/// Service Locator for dependency injection.
///
/// Repositories, services, and other dependencies are registered via
/// `@injectable` annotations and auto-generated. See `app_router.dart`
/// for the router.
final GetIt sl = GetIt.instance;

/// Initialize the DI container using [initDependencies].
///
/// Must be called after `SayrSupabase.instance.init()`.
@InjectableInit()
Future<void> initDependencies() async => sl.init();
