import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

/// Base class for all subscription-related events.
sealed class SubscriptionsEvent extends Equatable {
  /// Constructor for [SubscriptionsEvent].
  const SubscriptionsEvent();

  @override
  List<Object?> get props => [];
}

/// Event requesting subscriptions to be loaded.
class SubscriptionsLoadRequested extends SubscriptionsEvent {
  /// Creates a [SubscriptionsLoadRequested] event.
  const SubscriptionsLoadRequested();
}

/// Event requesting a subscription to be cancelled.
class SubscriptionCancelRequested extends SubscriptionsEvent {
  /// Creates a [SubscriptionCancelRequested] event.
  const SubscriptionCancelRequested(this.subscriptionId);

  /// The ID of the subscription to cancel.
  final SubscriptionId subscriptionId;

  @override
  List<Object?> get props => [subscriptionId];
}

/// Event requesting a license code to be activated.
class LicenseActivateRequested extends SubscriptionsEvent {
  /// Creates a [LicenseActivateRequested] event.
  const LicenseActivateRequested(this.code);

  /// The license code string.
  final String code;

  @override
  List<Object?> get props => [code];
}

/// Event requesting details of a license code to be fetched for preview.
class LicensePreviewRequested extends SubscriptionsEvent {
  /// Creates a [LicensePreviewRequested] event.
  const LicensePreviewRequested(this.code);

  /// The license code string.
  final String code;

  @override
  List<Object?> get props => [code];
}

/// Event requesting to reset the license preview state.
class LicensePreviewReset extends SubscriptionsEvent {
  /// Creates a [LicensePreviewReset] event.
  const LicensePreviewReset();
}
