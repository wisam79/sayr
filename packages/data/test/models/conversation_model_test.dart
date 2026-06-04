import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/conversation_model.dart';

void main() {
  group('ConversationModel', () {
    test('fromJson and toEntity mapping', () {
      final json = {
        'id': 'conv-1',
        'route_id': 'route-1',
        'student_id': 'student-1',
        'driver_user_id': 'driver-1',
        'created_at': '2026-06-04T12:00:00.000Z',
        'updated_at': '2026-06-04T12:30:00.000Z',
        'last_message_at': '2026-06-04T12:30:00.000Z',
        'last_message_preview': 'See you',
        'route_name': 'Baghdad Route',
        'other_user_name': 'Ahmad',
      };

      final model = ConversationModel.fromJson(json);
      expect(model.id, 'conv-1');
      expect(model.routeId, 'route-1');
      expect(model.studentId, 'student-1');
      expect(model.driverUserId, 'driver-1');
      expect(model.routeName, 'Baghdad Route');
      expect(model.otherUserName, 'Ahmad');

      final entity = model.toEntity();
      expect(entity.id, const ConversationId('conv-1'));
      expect(entity.routeId, const RouteId('route-1'));
      expect(entity.studentId, const UserId('student-1'));
      expect(entity.driverUserId, const UserId('driver-1'));
      expect(entity.routeName, 'Baghdad Route');
      expect(entity.otherUserName, 'Ahmad');
      expect(entity.lastMessagePreview, 'See you');
    });
  });
}
