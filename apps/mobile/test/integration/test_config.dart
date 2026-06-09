import 'package:sayr_core/sayr_core.dart';

// Simple test harness for integration tests
class TestAppConfig {
  static const testUserEmail = 'test@student.iq';
  static const testPassword = 'TestPass123!';
  static const testRouteId = 'route-test-123';
  static const testTripId = 'trip-test-456';
  static const testLicenseCode = 'ABC123';
  static const testInstitutionId = 'inst-test-001';
}

/// Creates a mock User for testing
User createTestUser({
  String id = 'test-user-id',
  String email = 'test@student.iq',
  UserRole role = UserRole.student,
  String fullName = 'Test Student',
  String phone = '+9647701234567',
  String institutionId = 'inst-test-001',
  bool isVerified = true,
}) {
  return User(
    id: UserId(id),
    email: email,
    role: role,
    fullName: fullName,
    phone: phone,
    institutionId: InstitutionId(institutionId),
    isVerified: isVerified,
  );
}
