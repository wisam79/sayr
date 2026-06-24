import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('User', () {
    test('displayName falls back to email prefix', () {
      const user = User(
        id: UserId('u1'),
        email: 'ahmed@example.com',
        role: UserRole.student,
      );
      expect(user.displayName, equals('ahmed'));
    });

    test('displayName uses fullName when available', () {
      const user = User(
        id: UserId('u1'),
        email: 'ahmed@example.com',
        role: UserRole.student,
        fullName: 'Ahmed Ali',
      );
      expect(user.displayName, equals('Ahmed Ali'));
    });

    test('isAdmin/isStudent/isDriver', () {
      const admin = User(id: UserId('1'), email: 'a@a', role: UserRole.admin);
      const student =
          User(id: UserId('2'), email: 's@s', role: UserRole.student);
      const driver = User(id: UserId('3'), email: 'd@d', role: UserRole.driver);

      expect(admin.isAdmin, isTrue);
      expect(student.isStudent, isTrue);
      expect(driver.isDriver, isTrue);
    });

    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'u1',
        'email': 'ahmed@example.com',
        'role': 'student',
        'fullName': 'Ahmed Ali',
      };
      final user = User.fromJson(json);
      expect(user.id, const UserId('u1'));
      expect(user.email, 'ahmed@example.com');
      expect(user.role, UserRole.student);
      expect(user.fullName, 'Ahmed Ali');
      expect(User.fromJson(user.toJson()), equals(user));
    });
  });

  group('Route', () {
    test('hasSeats reflects availableSeats', () {
      const route = Route(
        id: RouteId('r1'),
        driverId: DriverId('d1'),
        title: 'Test',
        startLocation: 'A',
        endLocation: 'B',
        price: Money(1000),
        capacity: 30,
        availableSeats: 0,
        isActive: true,
      );
      expect(route.hasSeats, isFalse);
    });

    test('occupancyRatio is between 0 and 1', () {
      const route = Route(
        id: RouteId('r1'),
        driverId: DriverId('d1'),
        title: 'Test',
        startLocation: 'A',
        endLocation: 'B',
        price: Money(1000),
        capacity: 30,
        availableSeats: 10,
        isActive: true,
      );
      expect(route.occupancyRatio, closeTo(20 / 30, 0.01));
    });

    test('occupancyRatio is 0 when capacity is 0', () {
      const route = Route(
        id: RouteId('r1'),
        driverId: DriverId('d1'),
        title: 'Test',
        startLocation: 'A',
        endLocation: 'B',
        price: Money(1000),
        capacity: 0,
        availableSeats: 0,
        isActive: true,
      );
      expect(route.occupancyRatio, equals(0));
    });

    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'r1',
        'driverId': 'd1',
        'title': 'Test',
        'startLocation': 'A',
        'endLocation': 'B',
        'price': 1000,
        'capacity': 30,
        'availableSeats': 10,
        'isActive': true,
      };
      final route = Route.fromJson(json);
      expect(route.id, const RouteId('r1'));
      expect(route.price, const Money(1000));
      expect(Route.fromJson(route.toJson()), equals(route));
    });
  });

  group('Subscription', () {
    test('isExpired when endDate is in the past', () {
      final subscription = Subscription(
        id: const SubscriptionId('s1'),
        studentId: const UserId('u1'),
        routeId: const RouteId('r1'),
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 40)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(subscription.isExpired, isTrue);
    });

    test('isExpired when status is expired', () {
      final subscription = Subscription(
        id: const SubscriptionId('s1'),
        studentId: const UserId('u1'),
        routeId: const RouteId('r1'),
        status: SubscriptionStatus.expired,
        startDate: DateTime.now().subtract(const Duration(days: 40)),
      );
      expect(subscription.isExpired, isTrue);
    });

    test('isActive when status is active and not expired', () {
      final now = DateTime.now();
      final subscription = Subscription(
        id: const SubscriptionId('s1'),
        studentId: const UserId('u1'),
        routeId: const RouteId('r1'),
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: DateTime(now.year + 1, now.month, now.day),
      );
      expect(subscription.isActive, isTrue);
      expect(subscription.isExpired, isFalse);
      expect(subscription.daysRemaining, greaterThanOrEqualTo(364));
    });

    test('isExpired is false when endDate is null', () {
      final subscription = Subscription(
        id: const SubscriptionId('s1'),
        studentId: const UserId('u1'),
        routeId: const RouteId('r1'),
        status: SubscriptionStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 40)),
      );
      expect(subscription.isExpired, isFalse);
    });

    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 's1',
        'studentId': 'u1',
        'routeId': 'r1',
        'status': 'active',
        'startDate': '2026-06-24T12:00:00.000Z',
        'endDate': '2026-07-24T12:00:00.000Z',
      };
      final subscription = Subscription.fromJson(json);
      expect(subscription.id, const SubscriptionId('s1'));
      expect(subscription.status, SubscriptionStatus.active);
      expect(
          subscription.startDate, DateTime.parse('2026-06-24T12:00:00.000Z'));
      expect(
          Subscription.fromJson(subscription.toJson()), equals(subscription));
    });
  });

  group('Trip', () {
    test('isCompleted when status is completed', () {
      final trip = Trip(
        id: const TripId('t1'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.completed,
        scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(trip.isCompleted, isTrue);
      expect(trip.isActive, isFalse);
    });

    test('isUpcoming when scheduledAt is in the future', () {
      final trip = Trip(
        id: const TripId('t1'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.scheduled,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(trip.isUpcoming, isTrue);
    });

    test('isCancelled when status is cancelled', () {
      final trip = Trip(
        id: const TripId('t1'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.cancelled,
        scheduledAt: DateTime.now(),
      );
      expect(trip.isCancelled, isTrue);
      expect(trip.isActive, isFalse);
    });

    test('isActive when status is driverWaiting or inTransit', () {
      final tripWaiting = Trip(
        id: const TripId('t1'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.driverWaiting,
        scheduledAt: DateTime.now(),
      );
      expect(tripWaiting.isActive, isTrue);

      final tripTransit = Trip(
        id: const TripId('t2'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.inTransit,
        scheduledAt: DateTime.now(),
      );
      expect(tripTransit.isActive, isTrue);
    });

    test('duration calculation when startedAt is set', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 30));
      final endTime = startTime.add(const Duration(minutes: 25));

      final tripCompleted = Trip(
        id: const TripId('t1'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.completed,
        scheduledAt: startTime,
        startedAt: startTime,
        endedAt: endTime,
      );
      expect(tripCompleted.duration, equals(const Duration(minutes: 25)));

      final tripInProgress = Trip(
        id: const TripId('t2'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.inTransit,
        scheduledAt: startTime,
        startedAt: startTime,
      );
      expect(tripInProgress.duration, isNotNull);
      expect(tripInProgress.duration!.inMinutes, greaterThanOrEqualTo(29));
    });

    test('duration is null when startedAt is null', () {
      final trip = Trip(
        id: const TripId('t1'),
        routeId: const RouteId('r1'),
        driverId: const DriverId('d1'),
        status: TripStatus.scheduled,
        scheduledAt: DateTime.now(),
      );
      expect(trip.duration, isNull);
    });

    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 't1',
        'routeId': 'r1',
        'driverId': 'd1',
        'status': 'scheduled',
        'scheduledAt': '2026-06-24T12:00:00.000Z',
        'startedAt': '2026-06-24T12:10:00.000Z',
        'endedAt': '2026-06-24T12:40:00.000Z',
      };
      final trip = Trip.fromJson(json);
      expect(trip.id, const TripId('t1'));
      expect(trip.status, TripStatus.scheduled);
      expect(Trip.fromJson(trip.toJson()), equals(trip));
    });
  });

  group('Rating', () {
    test('rating value is in 1-5 range', () {
      final rating = Rating(
        id: const RatingId('r1'),
        tripId: const TripId('t1'),
        studentId: const UserId('u1'),
        driverId: const DriverId('d1'),
        rating: 5,
        createdAt: DateTime.now(),
      );
      expect(rating.rating, greaterThanOrEqualTo(1));
      expect(rating.rating, lessThanOrEqualTo(5));
      expect(rating.isPositive, isTrue);
      expect(rating.isNegative, isFalse);
    });

    test('isNegative for 1-2 stars', () {
      final rating = Rating(
        id: const RatingId('r1'),
        tripId: const TripId('t1'),
        studentId: const UserId('u1'),
        driverId: const DriverId('d1'),
        rating: 1,
        createdAt: DateTime.now(),
      );
      expect(rating.isNegative, isTrue);
      expect(rating.isPositive, isFalse);
    });

    test('neutral rating (3 stars) is neither positive nor negative', () {
      final rating = Rating(
        id: const RatingId('r1'),
        tripId: const TripId('t1'),
        studentId: const UserId('u1'),
        driverId: const DriverId('d1'),
        rating: 3,
        createdAt: DateTime.now(),
      );
      expect(rating.isPositive, isFalse);
      expect(rating.isNegative, isFalse);
    });

    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'r1',
        'tripId': 't1',
        'studentId': 'u1',
        'driverId': 'd1',
        'rating': 5,
        'createdAt': '2026-06-24T12:00:00.000Z',
        'comment': 'Great driver',
      };
      final rating = Rating.fromJson(json);
      expect(rating.id, const RatingId('r1'));
      expect(rating.rating, 5);
      expect(rating.comment, 'Great driver');
      expect(rating.toJson(), json);
    });
  });

  group('AppConfig', () {
    test('isVersionOutdated compared correctly', () {
      const config = AppConfig(minVersion: '1.2.0');
      expect(config.isVersionOutdated('1.1.9'), isTrue);
      expect(config.isVersionOutdated('1.2.0'), isFalse);
      expect(config.isVersionOutdated('1.3.0'), isFalse);
      expect(config.isVersionOutdated('2.0.0'), isFalse);
    });

    test('fromJson and toJson roundtrip', () {
      const json = {
        'minVersion': '1.2.0',
        'maintenanceMode': true,
        'maintenanceMessage': 'Updating server',
        'updateUrl': 'https://example.com',
      };
      final config = AppConfig.fromJson(json);
      expect(config.minVersion, '1.2.0');
      expect(config.maintenanceMode, isTrue);
      expect(config.maintenanceMessage, 'Updating server');
      expect(config.updateUrl, 'https://example.com');
      expect(config.toJson(), json);
    });
  });

  group('Driver', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'drv-1',
        'userId': 'usr-1',
        'vehicleModel': 'Toyota',
        'vehiclePlate': '12345',
        'capacity': 30,
        'isVerified': true,
        'rating': 4.5,
      };
      final driver = Driver.fromJson(json);
      expect(driver.id, const DriverId('drv-1'));
      expect(driver.userId, const UserId('usr-1'));
      expect(driver.vehicleModel, 'Toyota');
      expect(driver.vehiclePlate, '12345');
      expect(driver.capacity, 30);
      expect(driver.isVerified, isTrue);
      expect(driver.rating, 4.5);
      expect(driver.toJson(), json);
    });
  });

  group('EmergencyReport', () {
    test('isActive works', () {
      final report = EmergencyReport(
        id: const EmergencyReportId('rep-1'),
        userId: const UserId('usr-1'),
        tripId: const TripId('tr-1'),
        createdAt: DateTime.now(),
      );
      expect(report.isActive, isTrue);

      final resolved = report.copyWith(resolvedAt: DateTime.now());
      expect(resolved.isActive, isFalse);
    });

    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'rep-1',
        'userId': 'usr-1',
        'tripId': 'tr-1',
        'createdAt': '2026-06-24T12:00:00.000Z',
        'location': {'latitude': 33.3, 'longitude': 44.4},
        'resolvedAt': '2026-06-24T13:00:00.000Z',
        'notes': 'SOS call',
      };
      final report = EmergencyReport.fromJson(json);
      expect(report.id, const EmergencyReportId('rep-1'));
      expect(report.isActive, isFalse);
      expect(
          report.location, const Coordinates(latitude: 33.3, longitude: 44.4));
      expect(report.toJson(), json);
    });
  });

  group('Institution', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'inst-1',
        'name': 'University of Baghdad',
        'city': 'Baghdad',
        'createdAt': '2026-06-24T12:00:00.000Z',
      };
      final institution = Institution.fromJson(json);
      expect(institution.id, const InstitutionId('inst-1'));
      expect(institution.name, 'University of Baghdad');
      expect(institution.city, 'Baghdad');
      expect(institution.createdAt, DateTime.parse('2026-06-24T12:00:00.000Z'));
      expect(institution.toJson(), json);
    });
  });

  group('License', () {
    test('isActivatable delegates to status', () {
      final license = License(
        id: const LicenseId('lic-1'),
        batchId: const LicenseBatchId('bat-1'),
        routeId: const RouteId('rt-1'),
        code: LicenseCode('ABC12345'),
        status: LicenseStatus.active,
        validDays: 30,
        createdAt: DateTime.now(),
      );
      expect(license.isActivatable, isTrue);
    });

    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'lic-1',
        'batchId': 'bat-1',
        'routeId': 'rt-1',
        'code': 'ABC12345',
        'status': 'active',
        'validDays': 30,
        'createdAt': '2026-06-24T12:00:00.000Z',
        'usedBy': 'usr-1',
        'usedAt': '2026-06-24T12:30:00.000Z',
      };
      final license = License.fromJson(json);
      expect(license.id, const LicenseId('lic-1'));
      expect(license.status, LicenseStatus.active);
      expect(license.code, LicenseCode('ABC12345'));
      expect(license.toJson(), json);

      final batchJson = {
        'id': 'bat-1',
        'createdBy': 'usr-1',
        'routeId': 'rt-1',
        'batchName': 'Batch A',
        'quantity': 50,
        'price': 15000,
        'validDays': 30,
        'createdAt': '2026-06-24T12:00:00.000Z',
      };
      final batch = LicenseBatch.fromJson(batchJson);
      expect(batch.id, const LicenseBatchId('bat-1'));
      expect(batch.price, 15000);
      expect(batch.toJson(), batchJson);
    });
  });

  group('LicensePreview', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'licenseId': 'lic-1',
        'routeId': 'rt-1',
        'routeTitle': 'Route A',
        'startLocation': 'Loc A',
        'endLocation': 'Loc B',
        'validDays': 30,
        'price': 15000,
        'availableSeats': 5,
        'status': 'available',
      };
      final preview = LicensePreview.fromJson(json);
      expect(preview.licenseId, const LicenseId('lic-1'));
      expect(preview.price, const Money(15000));
      expect(preview.toJson(), json);
    });
  });

  group('Message & Conversation', () {
    test('fromJson and toJson roundtrip', () {
      final messageJson = {
        'id': 'msg-1',
        'conversationId': 'conv-1',
        'senderId': 'usr-1',
        'body': 'Hello',
        'isRead': false,
        'createdAt': '2026-06-24T12:00:00.000Z',
      };
      final msg = Message.fromJson(messageJson);
      expect(msg.id, const MessageId('msg-1'));
      expect(msg.body, 'Hello');
      expect(msg.toJson(), messageJson);

      final convJson = {
        'id': 'conv-1',
        'routeId': 'rt-1',
        'studentId': 'usr-1',
        'driverUserId': 'usr-2',
        'createdAt': '2026-06-24T12:00:00.000Z',
        'updatedAt': '2026-06-24T12:00:00.000Z',
        'lastMessageAt': '2026-06-24T12:00:00.000Z',
        'lastMessagePreview': 'Hello',
        'routeName': 'Route A',
        'otherUserName': 'Driver Name',
      };
      final conv = Conversation.fromJson(convJson);
      expect(conv.id, const ConversationId('conv-1'));
      expect(conv.toJson(), convJson);
    });
  });

  group('AppNotification', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'not-1',
        'userId': 'usr-1',
        'title': 'Alert',
        'body': 'Message',
        'isRead': false,
        'createdAt': '2026-06-24T12:00:00.000Z',
        'data': {'type': 'alert'},
      };
      final notification = AppNotification.fromJson(json);
      expect(notification.id, const NotificationId('not-1'));
      expect(notification.data, {'type': 'alert'});
      expect(notification.toJson(), json);
    });
  });

  group('Payout', () {
    test('isPending works', () {
      final payout = Payout(
        id: const PayoutId('pay-1'),
        driverId: const DriverId('drv-1'),
        amount: const Money(50000),
        status: PayoutStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(payout.isPending, isTrue);

      final completed = payout.copyWith(status: PayoutStatus.completed);
      expect(completed.isPending, isFalse);
    });
  });
}
