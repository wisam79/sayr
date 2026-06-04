import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

sealed class SubscriptionsState extends Equatable {
  const SubscriptionsState();

  @override
  List<Object?> get props => [];
}

class SubscriptionsInitial extends SubscriptionsState {
  const SubscriptionsInitial();
}

class SubscriptionsLoading extends SubscriptionsState {
  const SubscriptionsLoading();
}

class SubscriptionsLoaded extends SubscriptionsState {
  const SubscriptionsLoaded(this.subscriptions);
  final List<Subscription> subscriptions;

  @override
  List<Object?> get props => [subscriptions];
}

class SubscriptionsError extends SubscriptionsState {
  const SubscriptionsError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class LicenseActivating extends SubscriptionsState {
  const LicenseActivating();
}

class LicenseActivated extends SubscriptionsState {
  const LicenseActivated(this.subscriptionId);
  final SubscriptionId subscriptionId;

  @override
  List<Object?> get props => [subscriptionId];
}
