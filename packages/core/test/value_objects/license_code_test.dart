import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('LicenseCode - tryParse', () {
    test('valid 8-character alphanumeric code', () {
      final code = LicenseCode.tryParse('A1B2C3D4');
      expect(code, isNotNull);
      expect(code!.value, equals('A1B2C3D4'));
    });

    test('lowercase is converted to uppercase', () {
      final code = LicenseCode.tryParse('a1b2c3d4');
      expect(code, isNotNull);
      expect(code!.value, equals('A1B2C3D4'));
    });

    test('whitespace is trimmed', () {
      final code = LicenseCode.tryParse('  A1B2C3D4  ');
      expect(code, isNotNull);
      expect(code!.value, equals('A1B2C3D4'));
    });

    test('rejects too short', () {
      expect(LicenseCode.tryParse('A1B2C3'), isNull);
    });

    test('rejects too long', () {
      expect(LicenseCode.tryParse('A1B2C3D4X'), isNull);
    });

    test('rejects special characters', () {
      expect(LicenseCode.tryParse('A1B2-3D4'), isNull);
      expect(LicenseCode.tryParse('A1B2 3D4'), isNull);
    });

    test('rejects empty string', () {
      expect(LicenseCode.tryParse(''), isNull);
    });
  });

  group('LicenseCode - factory', () {
    test('throws on invalid input', () {
      expect(
        () => LicenseCode('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('creates on valid input', () {
      final code = LicenseCode('A1B2C3D4');
      expect(code.value, equals('A1B2C3D4'));
    });
  });

  group('LicenseCode - formatting', () {
    test('formatted with dash separator', () {
      final code = LicenseCode('A1B2C3D4');
      expect(code.formatted, equals('A1B2-C3D4'));
    });
  });
}
