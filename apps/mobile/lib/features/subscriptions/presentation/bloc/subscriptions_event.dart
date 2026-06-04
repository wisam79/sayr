import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

sealed class SubscriptionsEvent extends Equatable {
  const SubscriptionsEvent();

  @override
  List<Object?> get props => [];
}

class SubscriptionsLoadRequested extends SubscriptionsEvent {
  const SubscriptionsLoadRequested();
}

class SubscriptionCancelRequested extends SubscriptionsEvent {
  const SubscriptionCancelRequested(this.subscriptionId);
  final SubscriptionId subscriptionId;

  @override
  List<Object?> get props => [subscriptionId];
}

class LicenseActivateRequested extends SubscriptionsEvent {
  const LicenseActivateRequested(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}
