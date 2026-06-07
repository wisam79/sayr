import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

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
            SubscriptionsInitial() => const LoadingWidget(),
            SubscriptionsLoading() => const LoadingWidget(),
            LicenseActivating() => const LoadingWidget(),
            LicenseActivated() => const LoadingWidget(),
            SubscriptionsError(:final failure) => AppErrorWidget(
                message: failure.message ?? l10n.errorOccurred,
                title: l10n.error,
                retryLabel: l10n.retry,
                onRetry: () {
                  context
                      .read<SubscriptionsBloc>()
                      .add(const SubscriptionsLoadRequested());
                },
              ),
            SubscriptionsLoaded(:final subscriptions)
                when subscriptions.isEmpty =>
              EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: l10n.noSubscriptionsTitle,
                subtitle: l10n.noSubscriptionsSubtitle,
                action: PrimaryButton(
                  label: l10n.activateLicense,
                  isExpanded: false,
                  onPressed: () => context.push('/activate-license'),
                ),
              ),
            SubscriptionsLoaded(:final subscriptions) => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                itemCount: subscriptions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  return _SubscriptionCard(subscription: sub);
                },
              ),
          };
        },
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActive = subscription.isActive && !subscription.isExpired;
    final endDateStr =
        subscription.endDate!.toLocal().toString().split(' ').first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Slidable(
        key: ValueKey(subscription.id.value),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            if (isActive)
              SlidableAction(
                onPressed: (context) {
                  context
                      .read<SubscriptionsBloc>()
                      .add(SubscriptionCancelRequested(subscription.id));
                },
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                icon: Icons.cancel_outlined,
                label: l10n.cancel,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                        color: isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.inputRadius),
                      ),
                      child: Text(
                        isActive
                            ? l10n.subscriptionStatusActive
                            : l10n.subscriptionStatusExpired,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.error,
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
                if (isActive) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<SubscriptionsBloc>()
                          .add(SubscriptionCancelRequested(subscription.id));
                    },
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
      ),
    );
  }
}
