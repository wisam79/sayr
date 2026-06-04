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

    test('fromString defaults to student on invalid', () {
      expect(UserRole.fromString('unknown'), equals(UserRole.student));
      expect(UserRole.fromString(''), equals(UserRole.student));
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
      expect(TripStatus.scheduled.isActive, isFalse);
      expect(TripStatus.completed.isActive, isFalse);
    });

    test('displayNameAr is non-empty', () {
      for (final status in TripStatus.values) {
        expect(status.displayNameAr, isNotEmpty);
      }
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

    test('fromString defaults to scheduled on invalid', () {
      expect(TripStatus.fromString('unknown'), equals(TripStatus.scheduled));
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
