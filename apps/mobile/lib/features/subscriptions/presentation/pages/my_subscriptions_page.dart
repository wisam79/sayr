import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Page displaying subscriptions purchased by the user.
class MySubscriptionsPage extends StatefulWidget {
  /// Creates a [MySubscriptionsPage].
  const MySubscriptionsPage({super.key, this.showAppBar = true});

  /// Whether to show the app bar on this page.
  final bool showAppBar;

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  List<PaymentInfo> _pendingPayments = [];

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionsBloc>().add(const SubscriptionsLoadRequested());
    _fetchPendingPayments();
  }

  Future<void> _fetchPendingPayments() async {
    if (!mounted) return;
    final result = await sl<PaymentRepository>().getPendingPayments();
    if (!mounted) return;
    result.fold(
      (failure) {},
      (payments) {
        setState(() {
          _pendingPayments = payments;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(l10n.mySubscriptions),
            )
          : null,
      floatingActionButton: BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
        builder: (context, state) {
          final showFab =
              state is SubscriptionsLoaded && state.subscriptions.isNotEmpty;
          if (!showFab) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => context.push('/activate-license'),
            icon: const Icon(Icons.add),
            label: Text(l10n.activateLicense),
          );
        },
      ),
      body: BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
        builder: (context, state) {
          return switch (state) {
            SubscriptionsInitial() ||
            SubscriptionsLoading() ||
            LicenseActivating() ||
            LicenseActivated() ||
            LicensePreviewLoading() ||
            LicensePreviewLoaded() ||
            LicensePreviewError() =>
              const _SkeletonLoading(),
            SubscriptionsError(:final failure) => AppErrorWidget(
                message: failure.toLocalizedString(context),
                title: l10n.error,
                retryLabel: l10n.retry,
                onRetry: () {
                  context
                      .read<SubscriptionsBloc>()
                      .add(const SubscriptionsLoadRequested());
                },
              ),
            SubscriptionsLoaded(:final subscriptions) => RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<SubscriptionsBloc>()
                      .add(const SubscriptionsLoadRequested());
                  await _fetchPendingPayments();
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (_pendingPayments.isNotEmpty) ...[
                      Text(
                        l10n.pendingPayments,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ..._pendingPayments.map(
                        (payment) => _PendingPaymentCard(payment: payment),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (subscriptions.isEmpty) ...[
                      if (_pendingPayments.isEmpty)
                        EmptyState(
                          icon: Icons.confirmation_number_outlined,
                          title: l10n.noSubscriptionsTitle,
                          subtitle: l10n.noSubscriptionsSubtitle,
                          action: PrimaryButton(
                            label: l10n.activateLicense,
                            isExpanded: false,
                            onPressed: () => context.push('/activate-license'),
                          ),
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                Text(
                                  l10n.noActiveSubscription,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                PrimaryButton(
                                  label: l10n.activateLicense,
                                  onPressed: () =>
                                      context.push('/activate-license'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      Text(
                        l10n.mySubscriptions,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...subscriptions.map(
                        (sub) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _SubscriptionCard(subscription: sub),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: List.generate(
          3,
          (_) => const Card(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 160),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Bone.circle(size: 16),
                      SizedBox(width: AppSpacing.xs),
                      Bone.text(width: 120),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Bone.text(width: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});
  final Subscription subscription;

  Future<void> _confirmAndCancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.cancelSubscriptionConfirm),
          content: Text(l10n.cancelSubscriptionConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );

    if ((confirmed ?? false) && context.mounted) {
      context
          .read<SubscriptionsBloc>()
          .add(SubscriptionCancelRequested(subscription.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCancellable = (subscription.status == SubscriptionStatus.active ||
            subscription.status == SubscriptionStatus.pending) &&
        !subscription.isExpired;
    final endDateStr =
        subscription.endDate!.toLocal().toString().split(' ').first;

    final String statusLabel;
    final Color statusColor;

    if (subscription.status == SubscriptionStatus.cancelled) {
      statusLabel = l10n.subscriptionStatusCancelled;
      statusColor = AppColors.textSecondary;
    } else if (subscription.isExpired) {
      statusLabel = l10n.subscriptionStatusExpired;
      statusColor = AppColors.error;
    } else {
      switch (subscription.status) {
        case SubscriptionStatus.active:
          statusLabel = l10n.subscriptionStatusActive;
          statusColor = AppColors.success;
        case SubscriptionStatus.pending:
          statusLabel = l10n.subscriptionStatusPending;
          statusColor = AppColors.warning;
        case SubscriptionStatus.expired:
          statusLabel = l10n.subscriptionStatusExpired;
          statusColor = AppColors.error;
        case SubscriptionStatus.cancelled:
          statusLabel = l10n.subscriptionStatusCancelled;
          statusColor = AppColors.textSecondary;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Slidable(
        key: ValueKey(subscription.id.value),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            if (isCancellable)
              SlidableAction(
                onPressed: _confirmAndCancel,
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                icon: Icons.cancel_outlined,
                label: l10n.cancel,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        child: GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.subscriptionType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.inputRadius),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (subscription.endDate != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.subscriptionEndsOn(endDateStr),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (subscription.daysRemaining != null)
                  Text(
                    l10n.subscriptionDaysLeft(subscription.daysRemaining!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
              if (isCancellable) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => _confirmAndCancel(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: Text(l10n.cancelSubscription),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  const _PendingPaymentCard({required this.payment});
  final PaymentInfo payment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.pendingPaymentCardTitle('${payment.amount}'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                  child: Text(
                    l10n.subscriptionStatusPending,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: l10n.resumePayment,
              icon: Icons.play_arrow,
              onPressed: () {
                context.push(
                  '/payment/${payment.routeId}/${payment.amount}?paymentId=${payment.id}&paymentUrl=${Uri.encodeComponent(payment.paymentUrl)}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
