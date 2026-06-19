import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/rating_model.dart';

void main() {
  group('RatingModel', () {
    test('fromJson creates valid RatingModel', () {
      final json = {
        'id': 'rat-1',
        'trip_id': 'trip-1',
        'student_id': 'student-1',
        'driver_id': 'driver-1',
        'rating': 5,
        'created_at': '2026-06-10T12:00:00Z',
        'comment': 'سائق ممتاز',
      };

      final model = RatingModel.fromJson(json);

      expect(model.id, 'rat-1');
      expect(model.tripId, 'trip-1');
      expect(model.studentId, 'student-1');
      expect(model.driverId, 'driver-1');
      expect(model.rating, 5);
      expect(model.createdAt, '2026-06-10T12:00:00Z');
      expect(model.comment, 'سائق ممتاز');
    });

    test('fromJson handles null comment', () {
      final json = {
        'id': 'rat-2',
        'trip_id': 'trip-2',
        'student_id': 'student-2',
        'driver_id': 'driver-2',
        'rating': 3,
        'created_at': '2026-06-10T14:00:00Z',
      };

      final model = RatingModel.fromJson(json);

      expect(model.comment, isNull);
    });

    test('toEntity converts to domain Rating', () {
      const model = RatingModel(
        id: 'rat-3',
        tripId: 'trip-3',
        studentId: 'student-3',
        driverId: 'driver-3',
        rating: 4,
        createdAt: '2026-06-10T16:00:00Z',
        comment: 'good',
      );

      final entity = model.toEntity();

      expect(entity.id, const RatingId('rat-3'));
      expect(entity.tripId, const TripId('trip-3'));
      expect(entity.studentId, const UserId('student-3'));
      expect(entity.driverId, const DriverId('driver-3'));
      expect(entity.rating, 4);
      expect(entity.createdAt, DateTime.utc(2026, 6, 10, 16));
      expect(entity.comment, 'good');
    });
  });
}
