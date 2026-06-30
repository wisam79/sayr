import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_event.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_state.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late MockPaymentRepository mockRepo;
  late PaymentBloc bloc;

  const testPaymentInfo = PaymentInfo(
    id: PaymentId('pay-123'),
    paymentUrl: 'https://zaincash.iq/pay',
    status: PaymentStatus.pending,
    amount: Money(5000),
    subscriptionId: SubscriptionId('sub-456'),
  );

  setUpAll(() {
    registerFallbackValue(const RouteId('fallback'));
  });

  setUp(() {
    mockRepo = MockPaymentRepository();
    bloc = PaymentBloc(paymentRepository: mockRepo);
  });

  tearDown(() => bloc.close());

  blocTest<PaymentBloc, PaymentState>(
    'emits [loading, urlReady, awaitingCompletion] on successful payment start',
    build: () => bloc,
    act: (bloc) {
      when(
        () => mockRepo.createPayment(
          routeId: any(named: 'routeId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          method: any(named: 'method'),
        ),
      ).thenAnswer((_) async => const Right(testPaymentInfo));

      when(() => mockRepo.getPaymentStatus(any())).thenAnswer(
        (_) async => Right(testPaymentInfo.copyWith(status: PaymentStatus.pending)),
      );

      bloc.add(
        const PaymentStartZainCash(
          routeId: RouteId('route-123'),
          amount: 5000,
          currency: 'IQD',
        ),
      );
    },
    expect: () => [
      isA<PaymentLoading>(),
      isA<PaymentUrlReady>(),
      isA<PaymentAwaitingCompletion>(),
    ],
  );

  blocTest<PaymentBloc, PaymentState>(
    'emits [loading, failed] on payment creation failure',
    build: () => bloc,
    act: (bloc) {
      when(
        () => mockRepo.createPayment(
          routeId: any(named: 'routeId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          method: any(named: 'method'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'payment creation failed')),
      );

      bloc.add(
        const PaymentStartZainCash(
          routeId: RouteId('route-123'),
          amount: 5000,
          currency: 'IQD',
        ),
      );
    },
    expect: () => [
      isA<PaymentLoading>(),
      isA<PaymentFailed>(),
    ],
  );

  blocTest<PaymentBloc, PaymentState>(
    'emits success when payment status is completed',
    build: () => bloc,
    act: (bloc) {
      when(
        () => mockRepo.createPayment(
          routeId: any(named: 'routeId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          method: any(named: 'method'),
        ),
      ).thenAnswer((_) async => const Right(testPaymentInfo));

      when(() => mockRepo.getPaymentStatus(any())).thenAnswer(
        (_) async => Right(testPaymentInfo.copyWith(status: PaymentStatus.completed)),
      );

      bloc.add(
        const PaymentStartZainCash(
          routeId: RouteId('route-123'),
          amount: 5000,
          currency: 'IQD',
        ),
      );
    },
    expect: () => [
      isA<PaymentLoading>(),
      isA<PaymentUrlReady>(),
      isA<PaymentAwaitingCompletion>(),
      isA<PaymentSuccess>(),
    ],
  );

  blocTest<PaymentBloc, PaymentState>(
    'emits [urlReady, awaitingCompletion] when PaymentResume is triggered and starts polling',
    build: () => bloc,
    act: (bloc) {
      when(() => mockRepo.getPaymentStatus(any())).thenAnswer(
        (_) async => Right(testPaymentInfo.copyWith(status: PaymentStatus.pending)),
      );

      bloc.add(
        const PaymentResume(
          paymentId: 'pay-123',
          paymentUrl: 'https://zaincash.iq/pay',
          amount: 5000,
          currency: 'IQD',
        ),
      );
    },
    expect: () => [
      isA<PaymentUrlReady>(),
      isA<PaymentAwaitingCompletion>(),
    ],
  );

  test(
      'emits PaymentFailed with payment_timeout when polling times out after 100 iterations',
      () {
    fakeAsync((async) {
      final localMockRepo = MockPaymentRepository();
      final localBloc = PaymentBloc(paymentRepository: localMockRepo);
      final subscription = localBloc.stream.listen((_) {});

      when(
        () => localMockRepo.createPayment(
          routeId: any(named: 'routeId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          method: any(named: 'method'),
        ),
      ).thenAnswer((_) => Future.value(const Right(testPaymentInfo)));

      when(() => localMockRepo.getPaymentStatus(any())).thenAnswer(
        (_) => Future.value(Right(testPaymentInfo.copyWith(status: PaymentStatus.pending))),
      );

      localBloc.add(
        const PaymentStartZainCash(
          routeId: RouteId('route-123'),
          amount: 5000,
          currency: 'IQD',
        ),
      );

      async
        ..flushMicrotasks()
        ..elapse(const Duration(milliseconds: 10))
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 300))
        ..flushMicrotasks();

      subscription.cancel();

      expect(
        localBloc.state,
        const PaymentState.failed(
          failure: BusinessRuleFailure(message: 'payment_timeout'),
        ),
      );

      localBloc.close();
    });
  });
}
