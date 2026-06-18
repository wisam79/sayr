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
  });
}
