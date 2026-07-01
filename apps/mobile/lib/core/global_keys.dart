import 'package:flutter/material.dart';

/// Global keys for the app to access root level navigation and messengers.
class GlobalKeys {
  /// The global scaffold messenger key.
  static GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// The global root navigator key.
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
