import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';

/// Bloc for managing subscriptions.
class SubscriptionsBloc extends Bloc<SubscriptionsEvent, SubscriptionsState> {
  /// Creates a [SubscriptionsBloc] with the given [subscriptionRepository].
  SubscriptionsBloc({
    required SubscriptionRepository subscriptionRepository,
  })  : _subscriptionRepository = subscriptionRepository,
        super(const SubscriptionsInitial()) {
    on<SubscriptionsLoadRequested>(_onLoadRequested);
    on<SubscriptionCancelRequested>(_onCancelRequested);
    on<LicenseActivateRequested>(_onActivateRequested);
    on<LicensePreviewRequested>(_onPreviewRequested);
    on<LicensePreviewReset>(_onPreviewReset);
  }

  final SubscriptionRepository _subscriptionRepository;

  Future<void> _onLoadRequested(
    SubscriptionsLoadRequested event,
    Emitter<SubscriptionsState> emit,
  ) async {
    emit(const SubscriptionsLoading());

    final result = await _subscriptionRepository.getMySubscriptions();

    if (isClosed) return;
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

    if (isClosed) return;
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
      emit(
        const SubscriptionsError(
          ValidationFailure(message: ''),
        ),
      );
      return;
    }

    emit(const LicenseActivating());

    final result = await _subscriptionRepository.activateLicense(code);

    if (isClosed) return;
    result.fold(
      (failure) => emit(SubscriptionsError(failure)),
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
