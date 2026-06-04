import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/subscription_model.dart';

void main() {
  group('SubscriptionModel', () {
    test('fromJson and toEntity mapping', () {
      final json = {
        'id': 'sub-1',
        'student_id': 'student-1',
        'route_id': 'route-1',
        'status': 'active',
        'start_date': '2026-06-01T00:00:00.000Z',
        'end_date': '2026-06-30T00:00:00.000Z',
        'cancelled_at': '2026-06-15T00:00:00.000Z',
      };

      final model = SubscriptionModel.fromJson(json);
      expect(model.id, 'sub-1');
      expect(model.status, 'active');

      final entity = model.toEntity();
      expect(entity.id, const SubscriptionId('sub-1'));
      expect(entity.status, SubscriptionStatus.active);
      expect(entity.startDate, DateTime.parse('2026-06-01T00:00:00.000Z'));
      expect(entity.endDate, DateTime.parse('2026-06-30T00:00:00.000Z'));
      expect(entity.cancelledAt, DateTime.parse('2026-06-15T00:00:00.000Z'));
    });
  });
}
