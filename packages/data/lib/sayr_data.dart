/// Sayr Data - Supabase + Drift layer
library sayr_data;

import 'package:injectable/injectable.dart';

export 'src/datasources/auth_remote_datasource.dart';
export 'src/datasources/boarding_remote_datasource.dart';
export 'src/datasources/chat_remote_datasource.dart';
export 'src/datasources/driver_location_service_impl.dart';
export 'src/datasources/emergency_remote_datasource.dart';
export 'src/datasources/local_datasource.dart';
export 'src/datasources/notification_remote_datasource.dart';
export 'src/datasources/osrm_remote_datasource.dart';
export 'src/datasources/remote_datasource.dart';
export 'src/datasources/route_remote_datasource.dart';
export 'src/datasources/subscription_remote_datasource.dart';
export 'src/datasources/trip_remote_datasource.dart';
// DI Module
export 'src/di/data_module.dart';
// Local DB
export 'src/local/app_database.dart';
export 'src/local/location_queue_dao.dart';
export 'src/local/tables.dart';
export 'src/models/boarding_record_model.dart';
export 'src/models/payment_info.dart';
export 'src/models/route_model.dart';
// Models
export 'src/models/user_model.dart';
// Repositories
export 'src/repositories/auth_repository.dart';
export 'src/repositories/base_repository.dart';
export 'src/repositories/boarding_repository.dart';
export 'src/repositories/chat_repository.dart';
export 'src/repositories/driver_repository.dart';
export 'src/repositories/emergency_repository.dart';
export 'src/repositories/notifications_repository.dart';
export 'src/repositories/payment_repository.dart';
export 'src/repositories/rating_repository.dart';
export 'src/repositories/route_repository.dart';
export 'src/repositories/routing_service_impl.dart';
export 'src/repositories/subscription_repository.dart';
export 'src/repositories/trip_repository.dart';
// Secure storage
export 'src/storage/secure_storage.dart';
// Supabase client
export 'src/supabase/supabase_client.dart';
export 'src/supabase/supabase_config.dart';

@InjectableInit.microPackage()
void initMicroPackage() {}
