import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/emergency_report_model.dart';

void main() {
  group('EmergencyReportModel', () {
    test('fromJson and toEntity mapping', () {
      final json = {
        'id': 'report-1',
        'user_id': 'user-1',
        'trip_id': 'trip-1',
        'latitude': 33.0,
        'longitude': 44.0,
        'created_at': '2026-06-04T12:00:00.000Z',
        'resolved_at': '2026-06-04T12:30:00.000Z',
        'notes': 'Resolved quickly',
      };

      final model = EmergencyReportModel.fromJson(json);
      expect(model.id, 'report-1');
      expect(model.latitude, 33.0);
      expect(model.longitude, 44.0);

      final entity = model.toEntity();
      expect(entity.id, const EmergencyReportId('report-1'));
      expect(entity.userId, const UserId('user-1'));
      expect(entity.tripId, const TripId('trip-1'));
      expect(
          entity.location, const Coordinates(latitude: 33.0, longitude: 44.0));
      expect(entity.createdAt, DateTime.parse('2026-06-04T12:00:00.000Z'));
      expect(entity.resolvedAt, DateTime.parse('2026-06-04T12:30:00.000Z'));
      expect(entity.notes, 'Resolved quickly');
    });
  });
}
