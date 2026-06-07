import 'dart:async';

import 'package:bloc/bloc.dart';
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
    on<PaymentPollStatus>(_onPollStatus);
    on<PaymentReset>(_onReset);
    on<PaymentStatusChanged>(_onStatusChanged);
  }

  final PaymentRepository _paymentRepository;
  StreamSubscription<dynamic>? _pollSubscription;
  bool _isPollingCanceled = false;

  @override
  Future<void> close() async {
    await _pollSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStartZainCash(
    PaymentStartZainCash event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentState.loading(message: 'جاري إنشاء الدفع...'));

    final result = await _paymentRepository.createPayment(
      routeId: event.routeId,
      amount: event.amount,
      currency: event.currency,
      method: 'zaincash',
    );

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

  Future<void> _onPollStatus(
    PaymentPollStatus event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentState.awaitingCompletion(paymentId: event.paymentId));

    await _pollSubscription?.cancel();
    _isPollingCanceled = false;

    // Perform initial check synchronously
    final initialResult =
        await _paymentRepository.getPaymentStatus(event.paymentId);
    if (!isClosed) {
      add(PaymentStatusChanged(result: initialResult));
    }

    if (_isPollingCanceled || isClosed) return;

    // Set up periodic polling
    _pollSubscription = Stream.periodic(
      const Duration(seconds: 3),
      (_) => _paymentRepository.getPaymentStatus(event.paymentId),
    ).takeWhile((_) => !_isPollingCanceled && !isClosed).listen((result) async {
      final r = await result;
      if (!isClosed && !_isPollingCanceled) {
        add(PaymentStatusChanged(result: r));
      }
    });
  }

  void _onStatusChanged(
    PaymentStatusChanged event,
    Emitter<PaymentState> emit,
  ) {
    event.result.fold(
      (Failure failure) {
        if (failure is! NetworkFailure) {
          emit(PaymentState.failed(failure: failure));
          _isPollingCanceled = true;
          unawaited(_pollSubscription?.cancel());
        }
      },
      (PaymentInfo payment) {
        if (payment.status == 'completed') {
          emit(
            PaymentState.success(
              subscriptionId: SubscriptionId(payment.subscriptionId),
            ),
          );
          _isPollingCanceled = true;
          unawaited(_pollSubscription?.cancel());
        } else if (payment.status == 'failed' || payment.status == 'expired') {
          emit(
            PaymentState.failed(
              failure: BusinessRuleFailure(
                message: 'فشل الدفع: ${payment.status}',
              ),
            ),
          );
          _isPollingCanceled = true;
          unawaited(_pollSubscription?.cancel());
        }
      },
    );
  }

  void _onReset(PaymentReset event, Emitter<PaymentState> emit) {
    unawaited(_pollSubscription?.cancel());
    _isPollingCanceled = true;
    emit(const PaymentState.initial());
  }
}
