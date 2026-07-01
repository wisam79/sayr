import 'package:flutter/material.dart';
import 'package:sayr_mobile/core/global_keys.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Intercepts global errors and exceptions logged by Talker to optionally
/// display a SnackBar to the user.
class GlobalErrorObserver extends TalkerObserver {
  @override
  void onError(TalkerError err) {
    super.onError(err);
    final fallback = _localizedFallback((l10n) => l10n.genericError);
    _showErrorSnackBar(err.message ?? fallback);
  }

  @override
  void onException(TalkerException err) {
    super.onException(err);
    // Ignore cancelled operations or silent exceptions
    if (err.exception.toString().contains('cancelled')) return;

    final fallback = _localizedFallback((l10n) => l10n.genericException);
    _showErrorSnackBar(err.message ?? fallback);
  }

  /// Attempt to resolve a localized string via the current navigator context.
  /// Falls back to a neutral message if no context is available.
  String _localizedFallback(String Function(AppLocalizations) selector) {
    final context = GlobalKeys.navigatorKey.currentContext;
    if (context != null) {
      try {
        return selector(AppLocalizations.of(context));
      } catch (_) {
        // AppLocalizations may not be available (e.g., during early startup).
      }
    }
    return 'An error occurred.';
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
