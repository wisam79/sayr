import 'package:test/test.dart';
import 'package:sayr_core/src/utils/string_utils.dart';

void main() {
  group('StringUtils.toCamelCase', () {
    test('converts snake_case to camelCase', () {
      expect('driver_waiting'.toCamelCase(), 'driverWaiting');
      expect('in_transit'.toCamelCase(), 'inTransit');
      expect('in_progress'.toCamelCase(), 'inProgress');
    });

    test('returns single word unchanged', () {
      expect('scheduled'.toCamelCase(), 'scheduled');
      expect('active'.toCamelCase(), 'active');
      expect('open'.toCamelCase(), 'open');
    });

    test('handles multiple underscores', () {
      expect('some_long_word'.toCamelCase(), 'someLongWord');
      expect('a_b_c_d'.toCamelCase(), 'aBCD');
    });

    test('handles empty string', () {
      expect(''.toCamelCase(), '');
    });
  });
}
