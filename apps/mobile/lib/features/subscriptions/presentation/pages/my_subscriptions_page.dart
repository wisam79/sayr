import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionsBloc>().add(const SubscriptionsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? GlassAppBar(
              title: Text(l10n.mySubscriptions),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: l10n.activateLicense,
                  onPressed: () async {
                    await context.push('/activate-license');
                    if (context.mounted) {
                      context
                          .read<SubscriptionsBloc>()
                          .add(const SubscriptionsLoadRequested());
                    }
                  },
                ),
              ],
            )
          : null,
      body: BlocConsumer<SubscriptionsBloc, SubscriptionsState>(
        listener: (context, state) {
          if (state is SubscriptionsError && state.subscriptions.isNotEmpty) {
            SayrFlash.error(
              context,
              state.failure.toLocalizedString(context),
            );
          }
        },
        builder: (context, state) {
          final pendingPayments = switch (state) {
            SubscriptionsLoaded(:final pendingPayments) => pendingPayments,
            SubscriptionsError(:final pendingPayments) => pendingPayments,
            _ => const <PaymentInfo>[],
          };

          return switch (state) {
            SubscriptionsInitial() ||
            SubscriptionsLoading() ||
            LicenseActivating() ||
            LicenseActivated() ||
            LicensePreviewLoading() ||
            LicensePreviewLoaded() ||
            LicensePreviewError() =>
              const _SkeletonLoading(),
            SubscriptionsError(:final failure, :final subscriptions)
                when subscriptions.isEmpty =>
              AppErrorWidget(
                message: failure.toLocalizedString(context),
                title: l10n.error,
                retryLabel: l10n.retry,
                onRetry: () {
                  context
                      .read<SubscriptionsBloc>()
                      .add(const SubscriptionsLoadRequested());
                },
              ),
            SubscriptionsLoaded(:final subscriptions) ||
            SubscriptionsError(:final subscriptions) =>
              RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<SubscriptionsBloc>()
                      .add(const SubscriptionsLoadRequested());
                },
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Premium Dashboard Header
                    _DashboardHeader(subscriptions: subscriptions),
                    const SizedBox(height: AppSpacing.lg),

                    if (pendingPayments.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.pendingPayments,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...pendingPayments.map(
                        (payment) => _PendingPaymentCard(payment: payment),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (subscriptions.isEmpty) ...[
                      if (pendingPayments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: EmptyState(
                            icon: Icons.confirmation_number_outlined,
                            title: l10n.noSubscriptionsTitle,
                            subtitle: l10n.noSubscriptionsSubtitle,
                            action: PrimaryButton(
                              label: l10n.activateLicense,
                              isExpanded: false,
                              onPressed: () async {
                                await context.push('/activate-license');
                                if (context.mounted) {
                                  context
                                      .read<SubscriptionsBloc>()
                                      .add(const SubscriptionsLoadRequested());
                                }
                              },
                            ),
                          ),
                        )
                      else
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.noActiveSubscription,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                PrimaryButton(
                                  label: l10n.activateLicense,
                                  onPressed: () async {
                                    await context.push('/activate-license');
                                    if (context.mounted) {
                                      context.read<SubscriptionsBloc>().add(
                                            const SubscriptionsLoadRequested(),
                                          );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.mySubscriptions,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
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

/// A premium visual dashboard header summarizing active subscriptions.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.subscriptions});
  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeSub = subscriptions.cast<Subscription?>().firstWhere(
          (s) =>
              s != null &&
              s.status == SubscriptionStatus.active &&
              !s.isExpired,
          orElse: () => null,
        );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activeSub != null) {
      final daysRemaining = activeSub.daysRemaining ?? 30;
      final progress = (daysRemaining / 30.0).clamp(0.0, 1.0);
      final endDateStr =
          activeSub.endDate?.toLocal().toString().split(' ').first ?? '';
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.subscriptionStatusActive,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.subscriptionDaysLeft(daysRemaining),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                activeSub.routeId.value.isNotEmpty
                    ? l10n.subscriptionType
                    : l10n.subscriptionType,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.subscriptionEndsOn(endDateStr),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No active subscription promo card
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            if (isDark)
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
            else
              Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.card_membership_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noActiveSubscription,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.noSubscriptionsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.activateLicense,
              icon: Icons.add_moderator_outlined,
              onPressed: () async {
                await context.push('/activate-license');
                if (context.mounted) {
                  context.read<SubscriptionsBloc>().add(
                        const SubscriptionsLoadRequested(),
                      );
                }
              },
            ),
          ],
        ),
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
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
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
        ],
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
        return SayrDialog(
          title: l10n.cancelSubscriptionConfirm,
          subtitle: l10n.cancelSubscriptionConfirmMessage,
          headerIcon: Icons.warning_amber_rounded,
          headerIconColor: AppColors.error,
          primaryLabel: l10n.confirm,
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
          secondaryLabel: l10n.cancel,
          onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
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
    final endDateStr = subscription.endDate != null
        ? subscription.endDate!.toLocal().toString().split(' ').first
        : '';

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
      borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isCancellable
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: isCancellable
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.subscriptionType,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (subscription.endDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.subscriptionEndsOn(endDateStr),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              if (subscription.daysRemaining != null && isCancellable) ...[
                const SizedBox(height: AppSpacing.md),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.subscriptionDaysLeft(subscription.daysRemaining!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    InkWell(
                      onTap: () => _confirmAndCancel(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          l10n.cancelSubscription,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                  ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(
                color: AppColors.warning,
                width: 6,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.pendingPaymentCardTitle('${payment.amount}'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.subscriptionStatusPending,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l10n.resumePayment,
                  icon: Icons.play_arrow,
                  onPressed: () {
                    final uri = Uri(
                      path: '/payment/${payment.routeId}/${payment.amount}',
                      queryParameters: {
                        'paymentId': payment.id,
                        'paymentUrl': payment.paymentUrl,
                      },
                    );
                    context.push(uri.toString());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
