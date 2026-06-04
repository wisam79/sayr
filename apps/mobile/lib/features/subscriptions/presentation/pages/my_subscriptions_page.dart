import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/subscriptions_bloc.dart';
import '../bloc/subscriptions_event.dart';
import '../bloc/subscriptions_state.dart';

class MySubscriptionsPage extends StatelessWidget {
  const MySubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySubscriptions),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/activate-license'),
        icon: const Icon(Icons.add),
        label: const Text('تفعيل ترخيص'),
      ),
      body: BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
        builder: (context, state) {
          return switch (state) {
            SubscriptionsInitial() => const LoadingWidget(),
            SubscriptionsLoading() => const LoadingWidget(),
            LicenseActivating() => const LoadingWidget(),
            LicenseActivated() => const LoadingWidget(),
            SubscriptionsError(:final failure) => AppErrorWidget(
                message: failure.message ?? 'حدث خطأ',
                onRetry: () {
                  context
                      .read<SubscriptionsBloc>()
                      .add(const SubscriptionsLoadRequested());
                },
              ),
            SubscriptionsLoaded(:final subscriptions) when subscriptions.isEmpty =>
              const EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'لا يوجد اشتراكات',
                subtitle: 'فعّل ترخيصك الأول للبدء',
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
    final isActive = subscription.isActive && !subscription.isExpired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اشتراك',
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
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                  child: Text(
                    isActive ? 'نشط' : 'منتهي',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive ? AppColors.success : AppColors.error,
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
                    'ينتهي: ${subscription.endDate!.toLocal().toString().split(' ').first}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (subscription.daysRemaining != null)
                Text(
                  'متبقي ${subscription.daysRemaining} يوم',
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
                child: const Text('إلغاء الاشتراك'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
