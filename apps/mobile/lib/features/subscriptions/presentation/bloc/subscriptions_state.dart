import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

/// Base class for all subscription states.
sealed class SubscriptionsState extends Equatable {
  /// Constructor for [SubscriptionsState].
  const SubscriptionsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when subscriptions are not loaded.
class SubscriptionsInitial extends SubscriptionsState {
  /// Constructor for [SubscriptionsInitial].
  const SubscriptionsInitial();
}

/// State when subscriptions are being loaded.
class SubscriptionsLoading extends SubscriptionsState {
  /// Constructor for [SubscriptionsLoading].
  const SubscriptionsLoading();
}

/// State when subscriptions have successfully loaded.
class SubscriptionsLoaded extends SubscriptionsState {
  /// Constructor for [SubscriptionsLoaded].
  const SubscriptionsLoaded(this.subscriptions);

  /// List of loaded subscriptions.
  final List<Subscription> subscriptions;

  @override
  List<Object?> get props => [subscriptions];
}

/// State when a subscription operation fails.
class SubscriptionsError extends SubscriptionsState {
  /// Constructor for [SubscriptionsError].
  const SubscriptionsError(this.failure);

  /// The failure details.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// State when a license code activation is in progress.
class LicenseActivating extends SubscriptionsState {
  /// Constructor for [LicenseActivating].
  const LicenseActivating();
}

/// State when a license code activation completes successfully.
class LicenseActivated extends SubscriptionsState {
  /// Constructor for [LicenseActivated].
  const LicenseActivated(this.subscriptionId);

  /// The newly created subscription ID.
  final SubscriptionId subscriptionId;

  @override
  List<Object?> get props => [subscriptionId];
}

/// State when details of a license code are being fetched for preview.
class LicensePreviewLoading extends SubscriptionsState {
  /// Constructor for [LicensePreviewLoading].
  const LicensePreviewLoading();
}

/// State when details of a license code have been successfully fetched for preview.
class LicensePreviewLoaded extends SubscriptionsState {
  /// Constructor for [LicensePreviewLoaded].
  const LicensePreviewLoaded(this.preview);

  /// The license preview details.
  final LicensePreview preview;

  @override
  List<Object?> get props => [preview];
}

/// State when fetching license details for preview fails.
class LicensePreviewError extends SubscriptionsState {
  /// Constructor for [LicensePreviewError].
  const LicensePreviewError(this.failure);

  /// The failure details.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
