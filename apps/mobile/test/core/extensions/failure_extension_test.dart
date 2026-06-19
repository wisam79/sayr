import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import '../../test_helpers.dart';

void main() {
  group('FailureLocalization Extension Tests', () {
    testWidgets('maps each Failure type to correct localized string', (tester) async {
      late BuildContext testContext;

      await pumpTestWidget(
        tester,
        Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      final l10n = AppLocalizations.of(testContext);

      // NetworkFailure
      expect(
        const NetworkFailure().toLocalizedString(testContext),
        equals(l10n.failureNetwork),
      );
      expect(
        const NetworkFailure(message: 'Custom network').toLocalizedString(testContext),
        equals('Custom network'),
      );

      // ServerFailure
      expect(
        const ServerFailure().toLocalizedString(testContext),
        equals(l10n.failureServer),
      );
      expect(
        const ServerFailure(message: 'Custom server').toLocalizedString(testContext),
        equals('Custom server'),
      );

      // UnauthorizedFailure
      expect(
        const UnauthorizedFailure().toLocalizedString(testContext),
        equals(l10n.failureUnauthorized),
      );

      // ForbiddenFailure
      expect(
        const ForbiddenFailure().toLocalizedString(testContext),
        equals(l10n.failureForbidden),
      );

      // NotFoundFailure
      expect(
        const NotFoundFailure().toLocalizedString(testContext),
        equals(l10n.failureNotFound),
      );
      expect(
        const NotFoundFailure(resource: 'license').toLocalizedString(testContext),
        equals(l10n.invalidLicenseCode),
      );

      // ValidationFailure
      expect(
        const ValidationFailure().toLocalizedString(testContext),
        equals(l10n.failureValidation),
      );
      expect(
        const ValidationFailure(message: 'trip_time_must_be_future').toLocalizedString(testContext),
        equals(l10n.tripTimeMustBeFuture),
      );
      expect(
        const ValidationFailure(message: 'invalid_license_code').toLocalizedString(testContext),
        equals(l10n.invalidLicenseCode),
      );
      expect(
        const ValidationFailure(message: 'bluetooth_disabled').toLocalizedString(testContext),
        equals(l10n.bluetoothRequired),
      );

      // RateLimitFailure
      expect(
        const RateLimitFailure().toLocalizedString(testContext),
        equals(l10n.failureRateLimit),
      );

      // CacheFailure
      expect(
        const CacheFailure().toLocalizedString(testContext),
        equals(l10n.failureCache),
      );

      // InvalidStateTransitionFailure
      expect(
        const InvalidStateTransitionFailure().toLocalizedString(testContext),
        equals(l10n.failureInvalidStateTransition),
      );

      // BusinessRuleFailure
      expect(
        const BusinessRuleFailure(message: 'already_has_active_subscription').toLocalizedString(testContext),
        equals(l10n.alreadyHasActiveSubscription),
      );
      expect(
        const BusinessRuleFailure(message: 'license_not_active').toLocalizedString(testContext),
        equals(l10n.licenseNotActive),
      );
      expect(
        const BusinessRuleFailure(message: 'other_business_rule').toLocalizedString(testContext),
        equals('other_business_rule'),
      );

      // UnknownFailure
      expect(
        const UnknownFailure().toLocalizedString(testContext),
        equals(l10n.failureUnknown),
      );
    });
  });
}
