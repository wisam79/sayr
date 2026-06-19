import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:test/test.dart';

void main() {
  group('JSON Converters — IDs', () {
    group('UserId', () {
      test('roundtrip non-nullable', () {
        final id = userIdFromJson('u-1');
        expect(id, const UserId('u-1'));
        expect(userIdToJson(id), 'u-1');
      });

      test('nullable with value', () {
        final id = nullableUserIdFromJson('u-1');
        expect(id, const UserId('u-1'));
        expect(nullableUserIdToJson(id), 'u-1');
      });

      test('nullable with null', () {
        expect(nullableUserIdFromJson(null), isNull);
        expect(nullableUserIdToJson(null), isNull);
      });
    });

    group('RouteId', () {
      test('roundtrip non-nullable', () {
        final id = routeIdFromJson('r-1');
        expect(id, const RouteId('r-1'));
        expect(routeIdToJson(id), 'r-1');
      });

      test('nullable null roundtrip', () {
        expect(nullableRouteIdFromJson(null), isNull);
        expect(nullableRouteIdToJson(null), isNull);
      });
    });

    group('TripId', () {
      test('roundtrip non-nullable', () {
        final id = tripIdFromJson('t-1');
        expect(id, const TripId('t-1'));
        expect(tripIdToJson(id), 't-1');
      });

      test('nullable null roundtrip', () {
        expect(nullableTripIdFromJson(null), isNull);
        expect(nullableTripIdToJson(null), isNull);
      });
    });

    group('SubscriptionId', () {
      test('roundtrip', () {
        final id = subscriptionIdFromJson('s-1');
        expect(id, const SubscriptionId('s-1'));
        expect(subscriptionIdToJson(id), 's-1');
      });

      test('nullable null', () {
        expect(nullableSubscriptionIdFromJson(null), isNull);
        expect(nullableSubscriptionIdToJson(null), isNull);
      });
    });

    group('LicenseId', () {
      test('roundtrip', () {
        final id = licenseIdFromJson('l-1');
        expect(id, const LicenseId('l-1'));
        expect(licenseIdToJson(id), 'l-1');
      });

      test('nullable null', () {
        expect(nullableLicenseIdFromJson(null), isNull);
        expect(nullableLicenseIdToJson(null), isNull);
      });
    });

    group('LicenseBatchId', () {
      test('roundtrip', () {
        final id = licenseBatchIdFromJson('lb-1');
        expect(id, const LicenseBatchId('lb-1'));
        expect(licenseBatchIdToJson(id), 'lb-1');
      });

      test('nullable null', () {
        expect(nullableLicenseBatchIdFromJson(null), isNull);
        expect(nullableLicenseBatchIdToJson(null), isNull);
      });
    });

    group('DriverId', () {
      test('roundtrip', () {
        final id = driverIdFromJson('d-1');
        expect(id, const DriverId('d-1'));
        expect(driverIdToJson(id), 'd-1');
      });

      test('nullable null', () {
        expect(nullableDriverIdFromJson(null), isNull);
        expect(nullableDriverIdToJson(null), isNull);
      });
    });

    group('InstitutionId', () {
      test('roundtrip', () {
        final id = institutionIdFromJson('i-1');
        expect(id, const InstitutionId('i-1'));
        expect(institutionIdToJson(id), 'i-1');
      });

      test('nullable null', () {
        expect(nullableInstitutionIdFromJson(null), isNull);
        expect(nullableInstitutionIdToJson(null), isNull);
      });
    });

    group('PayoutId', () {
      test('roundtrip', () {
        final id = payoutIdFromJson('p-1');
        expect(id, const PayoutId('p-1'));
        expect(payoutIdToJson(id), 'p-1');
      });

      test('nullable null', () {
        expect(nullablePayoutIdFromJson(null), isNull);
        expect(nullablePayoutIdToJson(null), isNull);
      });
    });

    group('RatingId', () {
      test('roundtrip', () {
        final id = ratingIdFromJson('rat-1');
        expect(id, const RatingId('rat-1'));
        expect(ratingIdToJson(id), 'rat-1');
      });

      test('nullable null', () {
        expect(nullableRatingIdFromJson(null), isNull);
        expect(nullableRatingIdToJson(null), isNull);
      });
    });

    group('ConversationId', () {
      test('roundtrip', () {
        final id = conversationIdFromJson('c-1');
        expect(id, const ConversationId('c-1'));
        expect(conversationIdToJson(id), 'c-1');
      });

      test('nullable null', () {
        expect(nullableConversationIdFromJson(null), isNull);
        expect(nullableConversationIdToJson(null), isNull);
      });
    });

    group('MessageId', () {
      test('roundtrip', () {
        final id = messageIdFromJson('m-1');
        expect(id, const MessageId('m-1'));
        expect(messageIdToJson(id), 'm-1');
      });

      test('nullable null', () {
        expect(nullableMessageIdFromJson(null), isNull);
        expect(nullableMessageIdToJson(null), isNull);
      });
    });

    group('NotificationId', () {
      test('roundtrip', () {
        final id = notificationIdFromJson('n-1');
        expect(id, const NotificationId('n-1'));
        expect(notificationIdToJson(id), 'n-1');
      });

      test('nullable null', () {
        expect(nullableNotificationIdFromJson(null), isNull);
        expect(nullableNotificationIdToJson(null), isNull);
      });
    });

    group('EmergencyReportId', () {
      test('roundtrip', () {
        final id = emergencyReportIdFromJson('e-1');
        expect(id, const EmergencyReportId('e-1'));
        expect(emergencyReportIdToJson(id), 'e-1');
      });

      test('nullable null', () {
        expect(nullableEmergencyReportIdFromJson(null), isNull);
        expect(nullableEmergencyReportIdToJson(null), isNull);
      });
    });

    group('BoardingId', () {
      test('roundtrip', () {
        final id = boardingIdFromJson('b-1');
        expect(id, const BoardingId('b-1'));
        expect(boardingIdToJson(id), 'b-1');
      });

      test('nullable null', () {
        expect(nullableBoardingIdFromJson(null), isNull);
        expect(nullableBoardingIdToJson(null), isNull);
      });
    });

    group('BoardingTokenId', () {
      test('roundtrip', () {
        final id = boardingTokenIdFromJson('bt-1');
        expect(id, const BoardingTokenId('bt-1'));
        expect(boardingTokenIdToJson(id), 'bt-1');
      });

      test('nullable null', () {
        expect(nullableBoardingTokenIdFromJson(null), isNull);
        expect(nullableBoardingTokenIdToJson(null), isNull);
      });
    });
  });

  group('JSON Converters — Coordinates', () {
    test('non-nullable roundtrip', () {
      final json = {'latitude': 33.3, 'longitude': 44.4};
      final coords = coordinatesFromJson(json);
      expect(coords.latitude, 33.3);
      expect(coords.longitude, 44.4);
      final back = coordinatesToJson(coords);
      expect(back['latitude'], 33.3);
      expect(back['longitude'], 44.4);
    });

    test('handles int values by converting to double', () {
      final json = {'latitude': 33, 'longitude': 44};
      final coords = coordinatesFromJson(json);
      expect(coords.latitude, 33.0);
      expect(coords.longitude, 44.0);
    });

    test('nullable with value', () {
      final json = {'latitude': 1.0, 'longitude': 2.0};
      final coords = nullableCoordinatesFromJson(json);
      expect(coords, isNotNull);
      expect(coords!.latitude, 1.0);
      final back = nullableCoordinatesToJson(coords);
      expect(back, isNotNull);
    });

    test('nullable with null', () {
      expect(nullableCoordinatesFromJson(null), isNull);
      expect(nullableCoordinatesToJson(null), isNull);
    });
  });

  group('JSON Converters — Money', () {
    test('non-nullable roundtrip', () {
      final money = moneyFromJson(25000);
      expect(money.amountInFils, 25000);
      expect(moneyToJson(money), 25000);
    });

    test('nullable with value', () {
      final money = nullableMoneyFromJson(5000);
      expect(money, isNotNull);
      expect(nullableMoneyToJson(money), 5000);
    });

    test('nullable with null', () {
      expect(nullableMoneyFromJson(null), isNull);
      expect(nullableMoneyToJson(null), isNull);
    });
  });

  group('JSON Converters — LicenseCode', () {
    test('non-nullable roundtrip', () {
      final code = licenseCodeFromJson('ABCDEF12');
      expect(code.value, 'ABCDEF12');
      expect(licenseCodeToJson(code), 'ABCDEF12');
    });

    test('nullable with value', () {
      final code = nullableLicenseCodeFromJson('XYZ789AB');
      expect(code, isNotNull);
      expect(nullableLicenseCodeToJson(code), 'XYZ789AB');
    });

    test('nullable with null', () {
      expect(nullableLicenseCodeFromJson(null), isNull);
      expect(nullableLicenseCodeToJson(null), isNull);
    });
  });

  group('JSON Converters — Enums', () {
    group('UserRole', () {
      test('roundtrip student', () {
        expect(userRoleFromJson('student'), UserRole.student);
        expect(userRoleToJson(UserRole.student), 'student');
      });

      test('roundtrip driver', () {
        expect(userRoleFromJson('driver'), UserRole.driver);
        expect(userRoleToJson(UserRole.driver), 'driver');
      });

      test('roundtrip admin', () {
        expect(userRoleFromJson('admin'), UserRole.admin);
        expect(userRoleToJson(UserRole.admin), 'admin');
      });

      test('nullable with null', () {
        expect(nullableUserRoleFromJson(null), isNull);
        expect(nullableUserRoleToJson(null), isNull);
      });

      test('nullable with value', () {
        expect(nullableUserRoleFromJson('driver'), UserRole.driver);
        expect(nullableUserRoleToJson(UserRole.driver), 'driver');
      });
    });

    group('TripStatus', () {
      test('roundtrip scheduled', () {
        expect(tripStatusFromJson('scheduled'), TripStatus.scheduled);
        expect(tripStatusToJson(TripStatus.scheduled), 'scheduled');
      });

      test('roundtrip in_transit via fromString', () {
        expect(tripStatusFromJson('in_transit'), TripStatus.inTransit);
      });

      test('nullable null', () {
        expect(nullableTripStatusFromJson(null), isNull);
        expect(nullableTripStatusToJson(null), isNull);
      });
    });

    group('LicenseStatus', () {
      test('roundtrip active', () {
        expect(licenseStatusFromJson('active'), LicenseStatus.active);
        expect(licenseStatusToJson(LicenseStatus.active), 'active');
      });

      test('nullable null', () {
        expect(nullableLicenseStatusFromJson(null), isNull);
        expect(nullableLicenseStatusToJson(null), isNull);
      });
    });

    group('PayoutStatus', () {
      test('roundtrip', () {
        expect(payoutStatusFromJson('pending'), PayoutStatus.pending);
        expect(payoutStatusToJson(PayoutStatus.pending), 'pending');
      });

      test('nullable null', () {
        expect(nullablePayoutStatusFromJson(null), isNull);
        expect(nullablePayoutStatusToJson(null), isNull);
      });
    });

    group('SubscriptionStatus', () {
      test('roundtrip', () {
        expect(
          subscriptionStatusFromJson('active'),
          SubscriptionStatus.active,
        );
        expect(
          subscriptionStatusToJson(SubscriptionStatus.active),
          'active',
        );
      });

      test('nullable null', () {
        expect(nullableSubscriptionStatusFromJson(null), isNull);
        expect(nullableSubscriptionStatusToJson(null), isNull);
      });
    });

    group('SupportStatus', () {
      test('roundtrip', () {
        expect(supportStatusFromJson('open'), SupportStatus.open);
        expect(supportStatusToJson(SupportStatus.open), 'open');
      });

      test('nullable null', () {
        expect(nullableSupportStatusFromJson(null), isNull);
        expect(nullableSupportStatusToJson(null), isNull);
      });
    });
  });
}
