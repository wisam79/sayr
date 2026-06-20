import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart' show GoRouter;

/// Converts a [Stream] into a [Listenable].
///
/// Use this to notify [GoRouter] to rebuild its routes when the [Stream] emits a new value.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream].
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
