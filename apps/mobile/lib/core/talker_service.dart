import 'package:injectable/injectable.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Module to register [Talker] in the dependency injection container.
@module
abstract class TalkerModule {
  /// Provides the global [Talker] instance.
  @lazySingleton
  Talker get talker => Talker();
}
