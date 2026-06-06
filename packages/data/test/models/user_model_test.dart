import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates valid UserModel', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'role': 'student',
        'full_name': 'Ahmed Ali',
        'phone': '07901234567',
        'institution_id': 'inst-1',
        'is_verified': true,
        'avatar_url': 'https://example.com/avatar.png',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'user-123');
      expect(model.email, 'test@example.com');
      expect(model.role, UserRole.student);
      expect(model.fullName, 'Ahmed Ali');
      expect(model.phone, '07901234567');
      expect(model.institutionId, 'inst-1');
      expect(model.isVerified, true);
      expect(model.avatarUrl, 'https://example.com/avatar.png');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'user-456',
        'email': 'minimal@example.com',
        'role': 'student',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'user-456');
      expect(model.email, 'minimal@example.com');
      expect(model.role, UserRole.student);
      expect(model.fullName, isNull);
      expect(model.phone, isNull);
      expect(model.institutionId, isNull);
      expect(model.isVerified, false);
      expect(model.avatarUrl, isNull);
    });

    test('fromJson parses driver role', () {
      final json = {
        'id': 'driver-1',
        'email': 'driver@example.com',
        'role': 'driver',
      };

      final model = UserModel.fromJson(json);
      expect(model.role, UserRole.driver);
    });

    test('fromJson parses admin role', () {
      final json = {
        'id': 'admin-1',
        'email': 'admin@example.com',
        'role': 'admin',
      };

      final model = UserModel.fromJson(json);
      expect(model.role, UserRole.admin);
    });

    test('toEntity converts to domain User', () {
      const model = UserModel(
        id: 'user-789',
        email: 'entity@example.com',
        role: UserRole.student,
        fullName: 'Test User',
        phone: '07900000000',
        isVerified: true,
      );

      final entity = model.toEntity();

      expect(entity.id, const UserId('user-789'));
      expect(entity.email, 'entity@example.com');
      expect(entity.role, UserRole.student);
      expect(entity.fullName, 'Test User');
      expect(entity.phone, '07900000000');
      expect(entity.isVerified, true);
    });
  });
}
