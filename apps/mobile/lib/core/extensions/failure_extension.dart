import 'package:flutter/material.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

/// Extension to map domain [Failure] instances to user-facing localized strings.
extension FailureLocalization on Failure {
  /// Converts the failure to a localized string using the current [BuildContext].
  String toLocalizedString(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return switch (this) {
      NetworkFailure() => message ?? l10n.failureNetwork,
      ServerFailure() => message ?? l10n.failureServer,
      UnauthorizedFailure() => message ?? l10n.failureUnauthorized,
      ForbiddenFailure() => message ?? l10n.failureForbidden,
      NotFoundFailure(:final resource) => switch (resource) {
          'license' => l10n.invalidLicenseCode,
          _ => message ?? l10n.failureNotFound,
        },
      ValidationFailure() => switch (message) {
          'trip_time_must_be_future' => l10n.tripTimeMustBeFuture,
          'invalid_license_code' => l10n.invalidLicenseCode,
          'bluetooth_disabled' => l10n.bluetoothRequired,
          _ => message ?? l10n.failureValidation,
        },
      RateLimitFailure() => message ?? l10n.failureRateLimit,
      CacheFailure() => message ?? l10n.failureCache,
      InvalidStateTransitionFailure() =>
        message ?? l10n.failureInvalidStateTransition,
      BusinessRuleFailure() => switch (message) {
          'already_has_active_subscription' =>
            l10n.alreadyHasActiveSubscription,
          'license_not_active' => l10n.licenseNotActive,
          _ => message ?? l10n.failureUnknown,
        },
      UnknownFailure() => message ?? l10n.failureUnknown,
    };
  }
}
