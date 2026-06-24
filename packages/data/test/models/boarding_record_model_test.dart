import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/boarding_record_model.dart';

void main() {
  group('BoardingRecordModel', () {
    test('fromJson and toEntity mapping with all fields', () {
      final json = {
        'id': 'record-1',
        'trip_id': 'trip-1',
        'student_id': 'student-1',
        'boarded_at': '2026-06-04T08:00:00.000Z',
        'subscription_id': 'sub-1',
        'student_name': 'Ahmad',
        'boarding_method': 'proximity',
      };

      final model = BoardingRecordModel.fromJson(json);
      expect(model.id, 'record-1');
      expect(model.tripId, 'trip-1');
      expect(model.studentId, 'student-1');
      expect(model.boardedAt, DateTime.parse('2026-06-04T08:00:00.000Z'));
      expect(model.subscriptionId, 'sub-1');
      expect(model.studentName, 'Ahmad');
      expect(model.boardingMethod, 'proximity');

      final entity = model.toEntity();
      expect(entity.id, const BoardingId('record-1'));
      expect(entity.tripId, const TripId('trip-1'));
      expect(entity.studentId, const UserId('student-1'));
      expect(entity.boardedAt, DateTime.parse('2026-06-04T08:00:00.000Z'));
      expect(entity.subscriptionId, const SubscriptionId('sub-1'));
      expect(entity.studentName, 'Ahmad');
      expect(entity.boardingMethod, 'proximity');
    });

    test('fromJson and toEntity mapping with default and null fields', () {
      final json = {
        'id': 'record-2',
        'trip_id': 'trip-2',
        'student_id': 'student-2',
        'boarded_at': '2026-06-04T08:00:00.000Z',
      };

      final model = BoardingRecordModel.fromJson(json);
      expect(model.subscriptionId, isNull);
      expect(model.studentName, isNull);
      expect(model.boardingMethod, 'qr_scan');

      final entity = model.toEntity();
      expect(entity.subscriptionId, isNull);
      expect(entity.studentName, isNull);
      expect(entity.boardingMethod, 'qr_scan');
    });

    test('toJson serialization', () {
      final model = BoardingRecordModel(
        id: 'record-3',
        tripId: 'trip-3',
        studentId: 'student-3',
        boardedAt: DateTime.parse('2026-06-04T08:00:00.000Z'),
        subscriptionId: 'sub-3',
        studentName: 'Ali',
        boardingMethod: 'manual',
      );

      final json = model.toJson();
      expect(json['id'], 'record-3');
      expect(json['trip_id'], 'trip-3');
      expect(json['student_id'], 'student-3');
      expect(json['boarded_at'], '2026-06-04T08:00:00.000Z');
      expect(json['subscription_id'], 'sub-3');
      expect(json['student_name'], 'Ali');
      expect(json['boarding_method'], 'manual');
    });
  });
}
