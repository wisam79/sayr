import 'package:flutter/material.dart';
import 'package:sayr_mobile/core/global_keys.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Intercepts global errors and exceptions logged by Talker to optionally
/// display a SnackBar to the user.
class GlobalErrorObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    super.onError(err);
    _showErrorSnackBar(err.message ?? 'حدث خطأ. يرجى المحاولة مرة أخرى.');
  }

  @override
  void onException(TalkerException err) {
    super.onException(err);
    // Ignore cancelled operations or silent exceptions
    if (err.exception.toString().contains('cancelled')) return;

    _showErrorSnackBar(err.message ?? 'حدث استثناء غير متوقع.');
  }

  void _showErrorSnackBar(String message) {
    final messenger = GlobalKeys.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    // Avoid showing excessive toast if already showing
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
