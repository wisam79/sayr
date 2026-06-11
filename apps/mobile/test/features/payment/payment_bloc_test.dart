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
  late MockPaymentRepository mockRepo;
  late PaymentBloc bloc;

  const testPaymentInfo = PaymentInfo(
    id: 'pay-123',
    paymentUrl: 'https://zaincash.iq/pay',
    status: 'pending',
    amount: 5000,
    subscriptionId: 'sub-456',
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
        (_) async => Right(testPaymentInfo.copyWith(status: 'pending')),
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
        (_) async => Right(testPaymentInfo.copyWith(status: 'completed')),
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
        (_) async => Right(testPaymentInfo.copyWith(status: 'pending')),
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
}
