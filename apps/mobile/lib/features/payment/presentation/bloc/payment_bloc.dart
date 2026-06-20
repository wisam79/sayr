import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/payment/presentation/bloc/payment_event.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_state.dart';

/// BLoC for the payment flow (Zain Cash).
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  /// Creates a [PaymentBloc] with the given [paymentRepository].
  PaymentBloc({
    required PaymentRepository paymentRepository,
  })  : _paymentRepository = paymentRepository,
        super(const PaymentState.initial()) {
    on<PaymentStartZainCash>(_onStartZainCash);
    on<PaymentResume>(_onResume);
    on<PaymentPollStatus>(_onPollStatus);
    on<PaymentReset>(_onReset);
    on<PaymentStatusChanged>(_onStatusChanged);
  }

  final PaymentRepository _paymentRepository;
  int _currentPollSession = 0;

  Future<void> _onStartZainCash(
    PaymentStartZainCash event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentState.loading());

    final result = await _paymentRepository.createPayment(
      routeId: event.routeId,
      amount: event.amount,
      currency: event.currency,
      method: 'zaincash',
    );

    if (isClosed) return;
    result.fold(
      (Failure failure) => emit(PaymentState.failed(failure: failure)),
      (PaymentInfo payment) {
        emit(
          PaymentState.urlReady(
            paymentUrl: payment.paymentUrl,
            paymentId: payment.id,
            amount: event.amount,
            currency: event.currency,
          ),
        );
        add(PaymentPollStatus(paymentId: payment.id));
      },
    );
  }

  void _onResume(
    PaymentResume event,
    Emitter<PaymentState> emit,
  ) {
    emit(
      PaymentState.urlReady(
        paymentUrl: event.paymentUrl,
        paymentId: event.paymentId,
        amount: event.amount,
        currency: event.currency,
      ),
    );
    add(PaymentPollStatus(paymentId: event.paymentId));
  }

  Future<void> _onPollStatus(
    PaymentPollStatus event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentState.awaitingCompletion(paymentId: event.paymentId));

    _currentPollSession++;
    final session = _currentPollSession;

    // Perform initial check synchronously
    final initialResult =
        await _paymentRepository.getPaymentStatus(event.paymentId);
    if (isClosed || session != _currentPollSession) return;
    add(PaymentStatusChanged(result: initialResult));

    // Start periodic polling in the background without overlapping requests
    unawaited(_startPolling(event.paymentId, session));
  }

  Future<void> _startPolling(String paymentId, int session) async {
    var iterations = 0;
    while (session == _currentPollSession && !isClosed) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (session != _currentPollSession || isClosed) return;

      iterations++;
      if (iterations >= 100) {
        add(
          const PaymentStatusChanged(
            result: Left(
              BusinessRuleFailure(message: 'payment_timeout'),
            ),
          ),
        );
        return;
      }

      final result = await _paymentRepository.getPaymentStatus(paymentId);
      if (session != _currentPollSession || isClosed) return;

      add(PaymentStatusChanged(result: result));
    }
  }

  void _onStatusChanged(
    PaymentStatusChanged event,
    Emitter<PaymentState> emit,
  ) {
    event.result.fold(
      (Failure failure) {
        if (failure is! NetworkFailure) {
          emit(PaymentState.failed(failure: failure));
          _currentPollSession++;
        }
      },
      (PaymentInfo payment) {
        if (payment.status == 'completed') {
          emit(
            PaymentState.success(
              subscriptionId: SubscriptionId(payment.subscriptionId),
            ),
          );
          _currentPollSession++;
        } else if (payment.status == 'failed' || payment.status == 'expired') {
          emit(
            PaymentState.failed(
              failure: BusinessRuleFailure(
                message: 'Payment failed: ${payment.status}',
              ),
            ),
          );
          _currentPollSession++;
        }
      },
    );
  }

  void _onReset(PaymentReset event, Emitter<PaymentState> emit) {
    _currentPollSession++;
    emit(const PaymentState.initial());
  }
}
