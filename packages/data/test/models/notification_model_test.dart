import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('fromJson and toEntity mapping', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'title': 'Hello',
        'body': 'Notification body',
        'is_read': true,
        'created_at': '2026-06-04T12:00:00.000Z',
        'data': {'key': 'value'},
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 'notif-1');
      expect(model.isRead, true);

      final entity = model.toEntity();
      expect(entity.id, const NotificationId('notif-1'));
      expect(entity.userId, const UserId('user-1'));
      expect(entity.title, 'Hello');
      expect(entity.body, 'Notification body');
      expect(entity.isRead, true);
      expect(entity.createdAt, DateTime.parse('2026-06-04T12:00:00.000Z'));
      expect(entity.data, {'key': 'value'});
    });
  });
}
