import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('Strongly-typed IDs', () {
    test('UserId preserves value', () {
      const id = UserId('user-abc');
      expect(id.value, 'user-abc');
    });

    test('RouteId preserves value', () {
      const id = RouteId('route-123');
      expect(id.value, 'route-123');
    });

    test('TripId preserves value', () {
      const id = TripId('trip-456');
      expect(id.value, 'trip-456');
    });

    test('SubscriptionId preserves value', () {
      const id = SubscriptionId('sub-1');
      expect(id.value, 'sub-1');
    });

    test('LicenseId preserves value', () {
      const id = LicenseId('lic-1');
      expect(id.value, 'lic-1');
    });

    test('LicenseBatchId preserves value', () {
      const id = LicenseBatchId('batch-1');
      expect(id.value, 'batch-1');
    });

    test('DriverId preserves value', () {
      const id = DriverId('drv-1');
      expect(id.value, 'drv-1');
    });

    test('InstitutionId preserves value', () {
      const id = InstitutionId('inst-1');
      expect(id.value, 'inst-1');
    });

    test('PayoutId preserves value', () {
      const id = PayoutId('payout-1');
      expect(id.value, 'payout-1');
    });

    test('RatingId preserves value', () {
      const id = RatingId('rating-1');
      expect(id.value, 'rating-1');
    });

    test('ConversationId preserves value', () {
      const id = ConversationId('conv-1');
      expect(id.value, 'conv-1');
    });

    test('MessageId preserves value', () {
      const id = MessageId('msg-1');
      expect(id.value, 'msg-1');
    });

    test('NotificationId preserves value', () {
      const id = NotificationId('notif-1');
      expect(id.value, 'notif-1');
    });

    test('EmergencyReportId preserves value', () {
      const id = EmergencyReportId('sos-1');
      expect(id.value, 'sos-1');
    });

    test('BoardingId preserves value', () {
      const id = BoardingId('board-1');
      expect(id.value, 'board-1');
    });

    test('BoardingTokenId preserves value', () {
      const id = BoardingTokenId('token-1');
      expect(id.value, 'token-1');
    });

    group('equality', () {
      test('same type same value are equal', () {
        const a = UserId('x');
        const b = UserId('x');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('same type different value are not equal', () {
        const a = UserId('x');
        const b = UserId('y');
        expect(a, isNot(equals(b)));
      });

      test('different type same value are not equal (type safety)', () {
        const userId = UserId('shared-uuid');
        const routeId = RouteId('shared-uuid');
        // They wrap the same string, but are different types.
        // In Equatable, props are [value] which is identical, but the
        // runtimeType differs so Equatable treats them as unequal.
        expect(userId, isNot(equals(routeId)));
      });

      test('TripId and DriverId with same value are not equal', () {
        const tripId = TripId('same');
        const driverId = DriverId('same');
        expect(tripId, isNot(equals(driverId)));
      });
    });

    group('toString', () {
      test('includes value', () {
        const id = UserId('abc-123');
        expect(id.toString(), contains('abc-123'));
      });
    });
  });
}
