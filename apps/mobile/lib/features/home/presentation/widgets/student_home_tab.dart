import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/digital_ticket_pass.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/quick_action_card.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/safety_tips_sheet.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.select<AuthBloc, core.User?>((bloc) {
      final state = bloc.state;
      if (state is AuthAuthenticated) return state.user;
      return null;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return GreetingCard(
                  isCompact: true,
                  title: l10n.helloUser(state.user.displayName),
                  subtitle: '',
                  avatarWidget: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      state.user.displayName.isNotEmpty
                          ? state.user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  badgeWidget: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.studentBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
            builder: (context, state) {
              if (state is SubscriptionsLoaded) {
                final active = state.subscriptions
                    .where((s) => s.isActive && !s.isExpired)
                    .toList();
                if (active.isEmpty) {
                  return const EmptyDigitalTicketPass();
                }
                return DigitalTicketPass(
                  subscription: active.first,
                  user: user,
                  onTap: () => context.push('/boarding'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.quickActions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: LucideIcons.search,
                      label: l10n.browseRoutes,
                      color: AppColors.primary,
                      onTap: () => context.read<HomeNavCubit>().selectTab(1),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: QuickActionCard(
                      icon: LucideIcons.map,
                      label: l10n.liveMap,
                      color: AppColors.secondary,
                      onTap: () => context.read<HomeNavCubit>().selectTab(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: LucideIcons.message_square,
                      label: l10n.chatSupport,
                      color: AppColors.info,
                      onTap: () => context.push('/chats'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: QuickActionCard(
                      icon: LucideIcons.shield,
                      label: l10n.safetyTips,
                      color: AppColors.warning,
                      onTap: () => showSafetyTipsBottomSheet(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
