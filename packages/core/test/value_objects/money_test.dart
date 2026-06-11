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
    test('format defaults to ar_IQ locale with IQD symbol', () {
      const money = Money(1000);
      // NumberFormat.currency(locale: 'ar_IQ', symbol: 'د.ع', decimalDigits: 0)
      // produces locale-specific thousand separators
      final result = money.format();
      expect(result, contains('1,000'));
      expect(result, contains('د.ع'));
    });

    test('format with thousand separators', () {
      const money = Money(1234567);
      final result = money.format();
      expect(result, contains('1,234,567'));
      expect(result, contains('د.ع'));
    });

    test('format with custom locale and symbol', () {
      const money = Money(5000);
      final result = money.format(locale: 'en_US', symbol: 'IQD ');
      expect(result, contains('5,000'));
      expect(result, contains('IQD'));
    });
  });
}
