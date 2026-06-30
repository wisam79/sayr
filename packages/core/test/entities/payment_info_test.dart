import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentInfo', () {
    test('equality and props', () {
      const a = PaymentInfo(
        id: PaymentId('pay-1'),
        status: PaymentStatus.completed,
        amount: Money(5000),
      );
      const b = PaymentInfo(
        id: PaymentId('pay-1'),
        status: PaymentStatus.completed,
        amount: Money(5000),
      );
      const c = PaymentInfo(
        id: PaymentId('pay-2'),
        status: PaymentStatus.completed,
        amount: Money(5000),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
