import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('UserRole', () {
    test('isAdmin', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.student.isAdmin, isFalse);
      expect(UserRole.driver.isAdmin, isFalse);
    });

    test('isDriver', () {
      expect(UserRole.driver.isDriver, isTrue);
      expect(UserRole.admin.isDriver, isFalse);
      expect(UserRole.student.isDriver, isFalse);
    });

    test('isStudent', () {
      expect(UserRole.student.isStudent, isTrue);
      expect(UserRole.admin.isStudent, isFalse);
      expect(UserRole.driver.isStudent, isFalse);
    });

    test('fromString parses valid value', () {
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('student'), equals(UserRole.student));
      expect(UserRole.fromString('driver'), equals(UserRole.driver));
    });

    test('fromString throws on invalid', () {
      expect(() => UserRole.fromString('unknown'), throwsArgumentError);
      expect(() => UserRole.fromString(''), throwsArgumentError);
    });
  });

  group('TripStatus', () {
    test('isTerminal', () {
      expect(TripStatus.completed.isTerminal, isTrue);
      expect(TripStatus.cancelled.isTerminal, isTrue);
      expect(TripStatus.scheduled.isTerminal, isFalse);
      expect(TripStatus.inTransit.isTerminal, isFalse);
    });

    test('isActive', () {
      expect(TripStatus.driverWaiting.isActive, isTrue);
      expect(TripStatus.inTransit.isActive, isTrue);
      expect(TripStatus.scheduled.isActive, isTrue);
      expect(TripStatus.completed.isActive, isFalse);
    });


    test('fromString parses snake_case', () {
      expect(
        TripStatus.fromString('driver_waiting'),
        equals(TripStatus.driverWaiting),
      );
      expect(
        TripStatus.fromString('in_transit'),
        equals(TripStatus.inTransit),
      );
    });

    test('fromString throws on invalid', () {
      expect(() => TripStatus.fromString('unknown'), throwsArgumentError);
    });
  });

  group('LicenseStatus', () {
    test('isActivatable only for active', () {
      expect(LicenseStatus.active.isActivatable, isTrue);
      expect(LicenseStatus.used.isActivatable, isFalse);
      expect(LicenseStatus.expired.isActivatable, isFalse);
      expect(LicenseStatus.revoked.isActivatable, isFalse);
    });
  });

  group('SubscriptionStatus', () {
    test('isActive only for active', () {
      expect(SubscriptionStatus.active.isActive, isTrue);
      expect(SubscriptionStatus.pending.isActive, isFalse);
      expect(SubscriptionStatus.expired.isActive, isFalse);
      expect(SubscriptionStatus.cancelled.isActive, isFalse);
    });
  });
}
