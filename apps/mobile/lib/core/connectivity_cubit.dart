import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit responsible for monitoring network connectivity.
/// Emits `true` if the device is offline, and `false` if it is online.
class ConnectivityCubit extends Cubit<bool> {
  /// Creates a [ConnectivityCubit] and starts listening to connectivity changes.
  ConnectivityCubit({Connectivity? connectivity}) : super(false) {
    _connectivity = connectivity ?? Connectivity();
    _subscribe();
  }

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _subscribe() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isNowOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (state != isNowOffline) {
        emit(isNowOffline);
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
