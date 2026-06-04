import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'payment_event.dart';
import 'payment_state.dart';

/// BLoC for the payment flow (Zain Cash).
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc({
    required TripRepository tripRepository,
  })  : _tripRepository = tripRepository,
        super(const PaymentState.initial()) {
    on<PaymentStartZainCash>(_onStartZainCash);
    on<PaymentPollStatus>(_onPollStatus);
    on<PaymentReset>(_onReset);
  }

  final TripRepository _tripRepository;
  Timer? _pollTimer;

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  Future<void> _onStartZainCash(
    PaymentStartZainCash event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentState.loading(message: 'جاري إنشاء الدفع...'));

    final Either<Failure, PaymentInfo> result =
        await _tripRepository.createPayment(
      routeId: event.routeId,
      amount: event.amount,
      currency: event.currency,
      method: 'zain_cash',
    );

    result.fold(
      (Failure failure) => emit(PaymentState.failed(failure: failure)),
      (PaymentInfo payment) {
        emit(PaymentState.urlReady(
          paymentUrl: payment.paymentUrl,
          paymentId: payment.id,
          amount: event.amount,
          currency: event.currency,
        ));
        add(PaymentPollStatus(paymentId: payment.id));
      },
    );
  }

  Future<void> _onPollStatus(
    PaymentPollStatus event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentState.awaitingCompletion(paymentId: event.paymentId));

    _pollTimer?.cancel();

    // Check status immediately
    final Either<Failure, PaymentInfo> initialResult =
        await _tripRepository.getPaymentStatus(event.paymentId);

    bool stopPolling = false;

    initialResult.fold(
      (Failure failure) {
        if (failure is! NetworkFailure) {
          emit(PaymentState.failed(failure: failure));
          stopPolling = true;
        }
      },
      (PaymentInfo payment) {
        if (payment.status == 'completed') {
          emit(PaymentState.success(
            subscriptionId: SubscriptionId(payment.subscriptionId),
          ));
          stopPolling = true;
        } else if (payment.status == 'failed' || payment.status == 'expired') {
          emit(PaymentState.failed(
            failure: BusinessRuleFailure(
              message: 'فشل الدفع: ${payment.status}',
            ),
          ));
          stopPolling = true;
        }
      },
    );

    if (stopPolling || isClosed) return;

    // Only start timer if still pending/network failure
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (isClosed) return;

      final Either<Failure, PaymentInfo> result =
          await _tripRepository.getPaymentStatus(event.paymentId);
      result.fold(
        (Failure failure) {
          if (failure is! NetworkFailure) {
            _pollTimer?.cancel();
            emit(PaymentState.failed(failure: failure));
          }
        },
        (PaymentInfo payment) {
          if (payment.status == 'completed') {
            _pollTimer?.cancel();
            emit(PaymentState.success(
              subscriptionId: SubscriptionId(payment.subscriptionId),
            ));
          } else if (payment.status == 'failed' ||
              payment.status == 'expired') {
            _pollTimer?.cancel();
            emit(PaymentState.failed(
              failure: BusinessRuleFailure(
                message: 'فشل الدفع: ${payment.status}',
              ),
            ));
          }
        },
      );
    });
  }

  void _onReset(PaymentReset event, Emitter<PaymentState> emit) {
    _pollTimer?.cancel();
    emit(const PaymentState.initial());
  }
}
