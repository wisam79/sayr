import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';

/// Bloc for managing subscriptions.
class SubscriptionsBloc extends Bloc<SubscriptionsEvent, SubscriptionsState> {
  /// Creates a [SubscriptionsBloc] with the given repositories.
  SubscriptionsBloc({
    required SubscriptionRepository subscriptionRepository,
    required PaymentRepository paymentRepository,
  })  : _subscriptionRepository = subscriptionRepository,
        _paymentRepository = paymentRepository,
        super(const SubscriptionsInitial()) {
    on<SubscriptionsLoadRequested>(_onLoadRequested);
    on<SubscriptionCancelRequested>(_onCancelRequested);
    on<LicenseActivateRequested>(_onActivateRequested);
    on<LicensePreviewRequested>(_onPreviewRequested);
    on<LicensePreviewReset>(_onPreviewReset);
  }

  final SubscriptionRepository _subscriptionRepository;
  final PaymentRepository _paymentRepository;

  Future<void> _onLoadRequested(
    SubscriptionsLoadRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(const SubscriptionsLoading());

    final results = await Future.wait([
      _subscriptionRepository.getMySubscriptions(),
      _paymentRepository.getPendingPayments(),
    ]);

    if (isClosed) return;

    final subsResult = results[0] as Either<Failure, List<Subscription>>;
    final paymentsResult = results[1] as Either<Failure, List<PaymentInfo>>;

    subsResult.fold(
      (Failure failure) => emit(SubscriptionsError(failure)),
      (List<Subscription> subs) {
        final pendingPayments = paymentsResult.fold(
          (Failure _) => <PaymentInfo>[], // Fallback to empty if payments fail
          (List<PaymentInfo> payments) => payments,
        );
        emit(SubscriptionsLoaded(subs, pendingPayments));
      },
    );
  }

  Future<void> _onCancelRequested(
    SubscriptionCancelRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    final result = await _subscriptionRepository.cancel(event.subscriptionId);

    if (isClosed) return;
    result.fold(
      (failure) {
        final current = state;
        final subs = <Subscription>[];
        final payments = <PaymentInfo>[];
        if (current is SubscriptionsLoaded) {
          subs.addAll(current.subscriptions);
          payments.addAll(current.pendingPayments);
        } else if (current is SubscriptionsError) {
          subs.addAll(current.subscriptions);
          payments.addAll(current.pendingPayments);
        }
        emit(SubscriptionsError(failure, subs, payments));
      },
      (_) => add(const SubscriptionsLoadRequested()),
    );
  }

  Future<void> _onActivateRequested(
    LicenseActivateRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    final code = LicenseCode.tryParse(event.code);
    if (code == null) {
      final current = state;
      final subs = <Subscription>[];
      final payments = <PaymentInfo>[];
      if (current is SubscriptionsLoaded) {
        subs.addAll(current.subscriptions);
        payments.addAll(current.pendingPayments);
      } else if (current is SubscriptionsError) {
        subs.addAll(current.subscriptions);
        payments.addAll(current.pendingPayments);
      }
      emit(
        SubscriptionsError(
          const ValidationFailure(message: 'invalid_license_code'),
          subs,
          payments,
        ),
      );
      return;
    }

    emit(const LicenseActivating());

    final result = await _subscriptionRepository.activateLicense(code);

    if (isClosed) return;
    result.fold(
      (failure) {
        final current = state;
        final subs = <Subscription>[];
        final payments = <PaymentInfo>[];
        if (current is SubscriptionsLoaded) {
          subs.addAll(current.subscriptions);
          payments.addAll(current.pendingPayments);
        } else if (current is SubscriptionsError) {
          subs.addAll(current.subscriptions);
          payments.addAll(current.pendingPayments);
        }
        emit(SubscriptionsError(failure, subs, payments));
      },
      (subId) {
        emit(LicenseActivated(subId));
        add(const SubscriptionsLoadRequested());
      },
    );
  }

  Future<void> _onPreviewRequested(
    LicensePreviewRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    final code = LicenseCode.tryParse(event.code);
    if (code == null) {
      emit(
        const LicensePreviewError(
          ValidationFailure(message: 'invalid_license_code'),
        ),
      );
      return;
    }

    emit(const LicensePreviewLoading());

    final result = await _subscriptionRepository.getLicenseDetails(code);

    if (isClosed) return;
    result.fold(
      (failure) => emit(LicensePreviewError(failure)),
      (LicensePreview preview) => emit(LicensePreviewLoaded(preview)),
    );
  }

  void _onPreviewReset(
    LicensePreviewReset event,
    Emitter<SubscriptionsState> emit,
  ) {
    emit(const SubscriptionsInitial());
  }
}
