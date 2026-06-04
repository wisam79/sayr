import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';

import 'subscriptions_event.dart';
import 'subscriptions_state.dart';

/// Bloc for managing subscriptions.
class SubscriptionsBloc extends Bloc<SubscriptionsEvent, SubscriptionsState> {
  SubscriptionsBloc({
    required SubscriptionRepository subscriptionRepository,
  })  : _subscriptionRepository = subscriptionRepository,
        super(const SubscriptionsInitial()) {
    on<SubscriptionsLoadRequested>(_onLoadRequested);
    on<SubscriptionCancelRequested>(_onCancelRequested);
    on<LicenseActivateRequested>(_onActivateRequested);
  }

  final SubscriptionRepository _subscriptionRepository;

  Future<void> _onLoadRequested(
    SubscriptionsLoadRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(const SubscriptionsLoading());

    final result = await _subscriptionRepository.getMySubscriptions();

    result.fold(
      (failure) => emit(SubscriptionsError(failure)),
      (subs) => emit(SubscriptionsLoaded(subs)),
    );
  }

  Future<void> _onCancelRequested(
    SubscriptionCancelRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    final result = await _subscriptionRepository.cancel(event.subscriptionId);

    result.fold(
      (failure) => emit(SubscriptionsError(failure)),
      (_) => add(const SubscriptionsLoadRequested()),
    );
  }

  Future<void> _onActivateRequested(
    LicenseActivateRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    final code = LicenseCode.tryParse(event.code);
    if (code == null) {
      emit(const SubscriptionsError(
        ValidationFailure(message: 'كود الترخيص غير صحيح'),
      ));
      return;
    }

    emit(const LicenseActivating());

    final result = await _subscriptionRepository.activateLicense(code);

    result.fold(
      (failure) => emit(SubscriptionsError(failure)),
      (subId) {
        emit(LicenseActivated(subId));
        add(const SubscriptionsLoadRequested());
      },
    );
  }
}
