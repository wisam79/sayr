import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money - operations', () {
    test('addition', () {
      const a = Money(1000);
      const b = Money(500);
      expect((a + b).amountInFils, equals(1500));
    });

    test('subtraction', () {
      const a = Money(1000);
      const b = Money(300);
      expect((a - b).amountInFils, equals(700));
    });

    test('multiplication', () {
      const a = Money(1000);
      expect((a * 3).amountInFils, equals(3000));
    });

    test('comparison', () {
      const a = Money(1000);
      const b = Money(500);
      const c = Money(1000);
      expect(a > b, isTrue);
      expect(b < a, isTrue);
      expect(a >= c, isTrue);
      expect(b <= a, isTrue);
    });

    test('isZero / isPositive / isNegative', () {
      expect(Money.zero.isZero, isTrue);
      expect(const Money(100).isPositive, isTrue);
      expect(const Money(-100).isNegative, isTrue);
    });
  });

  group('Money - formatting', () {
    test('format small amount', () {
      const money = Money(1000);
      expect(money.format(), equals('1,000 د.ع'));
    });

    test('format with thousand separators', () {
      const money = Money(1234567);
      expect(money.format(), equals('1,234,567 د.ع'));
    });
  });
}
