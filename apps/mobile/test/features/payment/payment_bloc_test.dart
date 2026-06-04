import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_event.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepo;
  late PaymentBloc bloc;

  setUp(() {
    mockRepo = MockTripRepository();
    bloc = PaymentBloc(tripRepository: mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  final testPayment = PaymentInfo(
    id: 'pay-1',
    status: 'pending',
    paymentUrl: 'https://zaincash.example.com/pay/123',
    amount: 50000,
    currency: 'IQD',
    subscriptionId: '',
  );

  group('PaymentBloc', () {
    test('initial state is PaymentInitial', () {
      expect(bloc.state, isA<PaymentInitial>());
    });

    blocTest<PaymentBloc, PaymentState>(
      'emits [Loading, UrlReady] when payment creation succeeds',
      build: () {
        when(() => mockRepo.createPayment(
              routeId: any(named: 'routeId'),
              amount: any(named: 'amount'),
              currency: any(named: 'currency'),
              method: any(named: 'method'),
            )).thenAnswer(
          (_) async => Right<Failure, PaymentInfo>(testPayment),
        );
        return PaymentBloc(tripRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const PaymentStartZainCash(
        routeId: RouteId('route-1'),
        amount: 50000,
        currency: 'IQD',
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentUrlReady>().having(
          (s) => s.paymentUrl,
          'paymentUrl',
          'https://zaincash.example.com/pay/123',
        ),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [Loading, Failed] when payment creation fails',
      build: () {
        when(() => mockRepo.createPayment(
              routeId: any(named: 'routeId'),
              amount: any(named: 'amount'),
              currency: any(named: 'currency'),
              method: any(named: 'method'),
            )).thenAnswer(
          (_) async => const Left<Failure, PaymentInfo>(
            ServerFailure(message: 'Payment gateway error'),
          ),
        );
        return PaymentBloc(tripRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const PaymentStartZainCash(
        routeId: RouteId('route-1'),
        amount: 50000,
        currency: 'IQD',
      )),
      expect: () => [
        isA<PaymentLoading>(),
        isA<PaymentFailed>(),
      ],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits PaymentInitial on reset',
      build: () => PaymentBloc(tripRepository: mockRepo),
      act: (bloc) => bloc.add(const PaymentReset()),
      expect: () => [isA<PaymentInitial>()],
    );
  });
}
