import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_event.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_state.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
  });

  late MockPaymentRepository mockRepo;
  late PaymentBloc bloc;

  setUp(() {
    mockRepo = MockPaymentRepository();
    bloc = PaymentBloc(paymentRepository: mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  const testPayment = PaymentInfo(
    id: 'pay-1',
    status: 'pending',
    paymentUrl: 'https://zaincash.example.com/pay/123',
    amount: 50000,
  );

  const completedPayment = PaymentInfo(
    id: 'pay-1',
    status: 'completed',
    paymentUrl: 'https://zaincash.example.com/pay/123',
    amount: 50000,
    subscriptionId: 'sub-1',
  );

  const failedPayment = PaymentInfo(
    id: 'pay-1',
    status: 'failed',
    paymentUrl: 'https://zaincash.example.com/pay/123',
    amount: 50000,
  );

  const expiredPayment = PaymentInfo(
    id: 'pay-1',
    status: 'expired',
    paymentUrl: 'https://zaincash.example.com/pay/123',
    amount: 50000,
  );

  group('PaymentBloc', () {
    test('initial state is PaymentInitial', () {
      expect(bloc.state, isA<PaymentInitial>());
    });

    blocTest<PaymentBloc, PaymentState>(
      'emits [Loading, UrlReady, AwaitingCompletion] '
      'when payment creation succeeds',
      build: () {
        when(
          () => mockRepo.createPayment(
            routeId: any(named: 'routeId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            method: any(named: 'method'),
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, PaymentInfo>(testPayment),
        );
        when(() => mockRepo.getPaymentStatus(any())).thenAnswer(
          (_) async => const Right<Failure, PaymentInfo>(testPayment),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const PaymentStartZainCash(
          routeId: RouteId('route-1'),
          amount: 50000,
          currency: 'IQD',
        ),
      ),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentUrlReady>().having(
          (s) => s.paymentUrl,
          'paymentUrl',
          'https://zaincash.example.com/pay/123',
        ),
        isA<PaymentAwaitingCompletion>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [Loading, Failed] when payment creation fails',
      build: () {
        when(
          () => mockRepo.createPayment(
            routeId: any(named: 'routeId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            method: any(named: 'method'),
          ),
        ).thenAnswer(
          (_) async => const Left<Failure, PaymentInfo>(
            ServerFailure(message: 'Payment gateway error'),
          ),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const PaymentStartZainCash(
          routeId: RouteId('route-1'),
          amount: 50000,
          currency: 'IQD',
        ),
      ),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentFailed>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits PaymentInitial on reset',
      build: () => PaymentBloc(paymentRepository: mockRepo),
      act: (bloc) => bloc.add(const PaymentReset()),
      expect: () => [isA<PaymentInitial>()],
    );

    blocTest<PaymentBloc, PaymentState>(
      'polling: payment status "completed" emits Success with SubscriptionId',
      build: () {
        when(() => mockRepo.getPaymentStatus('pay-1')).thenAnswer(
          (_) async => const Right<Failure, PaymentInfo>(completedPayment),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      seed: () => const PaymentAwaitingCompletion(paymentId: 'pay-1'),
      act: (bloc) => bloc.add(const PaymentPollStatus(paymentId: 'pay-1')),
      expect: () => [
        isA<PaymentSuccess>().having(
          (s) => s.subscriptionId,
          'subscriptionId',
          const SubscriptionId('sub-1'),
        ),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'polling: payment status "failed" emits Failed',
      build: () {
        when(() => mockRepo.getPaymentStatus('pay-1')).thenAnswer(
          (_) async => const Right<Failure, PaymentInfo>(failedPayment),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      seed: () => const PaymentAwaitingCompletion(paymentId: 'pay-1'),
      act: (bloc) => bloc.add(const PaymentPollStatus(paymentId: 'pay-1')),
      expect: () => [
        isA<PaymentFailed>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'polling: payment status "expired" emits Failed',
      build: () {
        when(() => mockRepo.getPaymentStatus('pay-1')).thenAnswer(
          (_) async => const Right<Failure, PaymentInfo>(expiredPayment),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      seed: () => const PaymentAwaitingCompletion(paymentId: 'pay-1'),
      act: (bloc) => bloc.add(const PaymentPollStatus(paymentId: 'pay-1')),
      expect: () => [
        isA<PaymentFailed>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'polling: NetworkFailure continues polling (does not emit Failed)',
      build: () {
        when(() => mockRepo.getPaymentStatus('pay-1')).thenAnswer(
          (_) async => const Left<Failure, PaymentInfo>(
            NetworkFailure(message: 'No connection'),
          ),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      seed: () => const PaymentAwaitingCompletion(paymentId: 'pay-1'),
      act: (bloc) => bloc.add(const PaymentPollStatus(paymentId: 'pay-1')),
      expect: () => <dynamic>[],
    );

    blocTest<PaymentBloc, PaymentState>(
      'close() cancels the poll timer',
      build: () {
        when(() => mockRepo.getPaymentStatus('pay-1')).thenAnswer(
          (_) async => const Right<Failure, PaymentInfo>(testPayment),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      seed: () => const PaymentAwaitingCompletion(paymentId: 'pay-1'),
      act: (bloc) async {
        bloc.add(const PaymentPollStatus(paymentId: 'pay-1'));
        await Future<void>.delayed(Duration.zero);
        await bloc.close();
      },
      verify: (_) {
        verify(() => mockRepo.getPaymentStatus('pay-1')).called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'reset cancels active timer',
      build: () {
        when(() => mockRepo.getPaymentStatus('pay-1')).thenAnswer(
          (_) async => const Right<Failure, PaymentInfo>(testPayment),
        );
        return PaymentBloc(paymentRepository: mockRepo);
      },
      seed: () => const PaymentAwaitingCompletion(paymentId: 'pay-1'),
      act: (bloc) async {
        bloc.add(const PaymentPollStatus(paymentId: 'pay-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PaymentReset());
      },
      expect: () => [
        isA<PaymentInitial>(),
      ],
    );
  });
}
