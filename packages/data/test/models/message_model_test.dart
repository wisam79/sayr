import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/message_model.dart';

void main() {
  group('MessageModel', () {
    test('fromJson and toEntity mapping', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'body': 'Hello',
        'is_read': true,
        'created_at': '2026-06-04T12:00:00.000Z',
      };

      final model = MessageModel.fromJson(json);
      expect(model.id, 'msg-1');
      expect(model.conversationId, 'conv-1');
      expect(model.senderId, 'user-1');
      expect(model.body, 'Hello');
      expect(model.isRead, true);
      expect(model.createdAt, DateTime.parse('2026-06-04T12:00:00.000Z'));

      final entity = model.toEntity();
      expect(entity.id, const MessageId('msg-1'));
      expect(entity.conversationId, const ConversationId('conv-1'));
      expect(entity.senderId, const UserId('user-1'));
      expect(entity.body, 'Hello');
      expect(entity.isRead, true);
      expect(entity.createdAt, DateTime.parse('2026-06-04T12:00:00.000Z'));
    });
  });
}
