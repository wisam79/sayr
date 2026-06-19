import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentInfo', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'pay-123',
        'status': 'completed',
        'amount': 15000,
        'payment_url': 'https://pay.example.com/IQD/123',
        'currency': 'IQD',
        'subscription_id': 'sub-456',
        'route_id': 'route-789',
      };

      final paymentInfo = PaymentInfo.fromJson(json);
      expect(paymentInfo.id, 'pay-123');
      expect(paymentInfo.status, 'completed');
      expect(paymentInfo.amount, 15000);
      expect(paymentInfo.paymentUrl, 'https://pay.example.com/IQD/123');
      expect(paymentInfo.currency, 'IQD');
      expect(paymentInfo.subscriptionId, 'sub-456');
      expect(paymentInfo.routeId, 'route-789');

      final serialized = paymentInfo.toJson();
      expect(serialized, equals(json));
    });

    test('fromJson sets default values for optional fields', () {
      final json = {
        'id': 'pay-456',
        'status': 'pending',
        'amount': 20000,
      };

      final paymentInfo = PaymentInfo.fromJson(json);
      expect(paymentInfo.id, 'pay-456');
      expect(paymentInfo.status, 'pending');
      expect(paymentInfo.amount, 20000);
      expect(paymentInfo.paymentUrl, '');
      expect(paymentInfo.currency, 'IQD');
      expect(paymentInfo.subscriptionId, '');
      expect(paymentInfo.routeId, '');
    });

    test('equality and props', () {
      const a = PaymentInfo(
        id: 'pay-1',
        status: 'success',
        amount: 5000,
      );
      const b = PaymentInfo(
        id: 'pay-1',
        status: 'success',
        amount: 5000,
      );
      const c = PaymentInfo(
        id: 'pay-2',
        status: 'success',
        amount: 5000,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
