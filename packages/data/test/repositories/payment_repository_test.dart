import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'package:talker_flutter/talker_flutter.dart';

class MockRemoteDatasource extends Mock implements RemoteDatasource {}

void main() {
  late PaymentRepositoryImpl repository;
  late MockRemoteDatasource mockRemote;

  setUp(() {
    mockRemote = MockRemoteDatasource();
    repository = PaymentRepositoryImpl(
      remoteDatasource: mockRemote,
      talker: Talker(),
    );
  });

  group('PaymentRepositoryImpl', () {
    final mockPaymentJson = {
      'id': 'pay-123',
      'status': 'pending',
      'amount': 15000,
      'reference_url': 'https://test.zaincash.iq/transaction/pay-123',
      'currency': 'IQD',
      'subscription_id': 'sub-456',
      'route_id': 'route-789',
    };

    group('createPayment', () {
      test('returns PaymentInfo on success', () async {
        when(
          () => mockRemote.createPayment(
            routeId: 'route-789',
            amount: 15000,
            currency: 'IQD',
            method: 'zaincash',
          ),
        ).thenAnswer((_) async => mockPaymentJson);

        final result = await repository.createPayment(
          routeId: const RouteId('route-789'),
          amount: 15000,
          currency: 'IQD',
          method: 'zaincash',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (payment) {
            expect(payment.id, 'pay-123');
            expect(payment.status, 'pending');
            expect(payment.amount, 15000);
            expect(
              payment.paymentUrl,
              'https://test.zaincash.iq/transaction/pay-123',
            );
            expect(payment.routeId, 'route-789');
          },
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(
          () => mockRemote.createPayment(
            routeId: 'route-789',
            amount: 15000,
            currency: 'IQD',
            method: 'zaincash',
          ),
        ).thenThrow(Exception('Zain Cash API error'));

        final result = await repository.createPayment(
          routeId: const RouteId('route-789'),
          amount: 15000,
          currency: 'IQD',
          method: 'zaincash',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getPaymentStatus', () {
      test('returns PaymentInfo on success', () async {
        when(() => mockRemote.getPaymentStatus('pay-123'))
            .thenAnswer((_) async => mockPaymentJson);

        final result = await repository.getPaymentStatus('pay-123');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (payment) {
            expect(payment.id, 'pay-123');
            expect(payment.status, 'pending');
            expect(payment.amount, 15000);
            expect(
              payment.paymentUrl,
              'https://test.zaincash.iq/transaction/pay-123',
            );
            expect(payment.routeId, 'route-789');
          },
        );
      });

      test('returns NotFoundFailure when payment is null', () async {
        when(() => mockRemote.getPaymentStatus('pay-123'))
            .thenAnswer((_) async => null);

        final result = await repository.getPaymentStatus('pay-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('should fail'),
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getPaymentStatus('pay-123'))
            .thenThrow(Exception('DB error'));

        final result = await repository.getPaymentStatus('pay-123');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });

    group('getPendingPayments', () {
      test('returns List<PaymentInfo> on success', () async {
        when(() => mockRemote.getPendingPayments())
            .thenAnswer((_) async => [mockPaymentJson]);

        final result = await repository.getPendingPayments();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('should succeed'),
          (payments) {
            expect(payments.length, 1);
            expect(payments.first.id, 'pay-123');
            expect(payments.first.status, 'pending');
            expect(
              payments.first.paymentUrl,
              'https://test.zaincash.iq/transaction/pay-123',
            );
          },
        );
      });

      test('returns ServerFailure when remote throws exception', () async {
        when(() => mockRemote.getPendingPayments())
            .thenThrow(Exception('API error'));

        final result = await repository.getPendingPayments();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('should fail'),
        );
      });
    });
  });
}
