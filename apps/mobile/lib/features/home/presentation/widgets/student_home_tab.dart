import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/digital_ticket_pass.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
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

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorderColor =
        isDark ? AppColors.borderDark : Colors.grey.shade200;
    final primaryTextColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? AppColors.textMuted : AppColors.textSecondary;
    final buttonBorderColor =
        isDark ? AppColors.borderDark : Colors.grey.shade300;
    final primaryAccentColor =
        isDark ? AppColors.primaryDark : AppColors.primary;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        top: statusBarHeight + AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Custom Header
          Row(
            textDirection:
                TextDirection.ltr, // Ensures Bell on Left, Chat on Right
            children: [
              // Notifications Bell on Left
              BlocSelector<NotificationsBloc, NotificationsState, int>(
                selector: (state) => state.maybeWhen(
                  loaded: (_, count) => count,
                  orElse: () => 0,
                ),
                builder: (context, unread) {
                  return Semantics(
                    label: unread > 0
                        ? '${l10n.notifications}, $unread ${l10n.unread}'
                        : l10n.notifications,
                    child: IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            LucideIcons.bell,
                            color: primaryTextColor,
                            size: 24,
                          ),
                          if (unread > 0)
                            PositionedDirectional(
                              top: -2,
                              end: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                  );
                },
              ),
              // Greeting inside Center
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user != null
                          ? l10n.helloUser(user.displayName)
                          : 'مرحباً بك',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                            fontSize: 18,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'مرحباً بك في رحلات',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor,
                                    fontSize: 13,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '👋',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chat support on Right
              IconButton(
                icon: Icon(
                  LucideIcons.message_square,
                  color: primaryTextColor,
                  size: 24,
                ),
                tooltip: l10n.chats,
                onPressed: () => context.push('/chats'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Student Profile Card (Solid teal with white content)
          if (user != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                textDirection:
                    TextDirection.ltr, // Left: avatar, Right: details
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.displayName.trim().isNotEmpty
                          ? user.displayName.trim()[0].toUpperCase()
                          : 'W',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.studentBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Subscription Section (Adaptive card background and borders, no shadows)
          BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
            builder: (context, state) {
              if (state is SubscriptionsLoaded) {
                final active = state.subscriptions
                    .where((s) => s.isActive && !s.isExpired)
                    .toList();
                if (active.isEmpty) {
                  return const EmptyDigitalTicketPass();
                }
                final sub = active.first;
                final daysLeft = sub.daysRemaining ?? 0;
                const totalDays = 30.0;
                final progress = (daysLeft / totalDays).clamp(0.0, 1.0);
                final endDateStr = sub.endDate != null
                    ? sub.endDate!.toLocal().toString().split(' ').first
                    : '';

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorderColor),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Right Side: Title and dates (RTL starts here)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.mySubscriptions,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: primaryTextColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.subscriptionDaysLeft(daysLeft),
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.subscriptionEndsOn(endDateStr),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Left Side: Active badge and Progress Indicator
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.subscriptionStatusActive,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${(progress * 100).round()}%',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 80,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDark
                                        ? AppColors.dividerDark
                                        : Colors.grey.shade200,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Button: Show Digital Ticket Pass (Boarding)
                      InkWell(
                        onTap: () => context.push('/boarding'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: buttonBorderColor),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    color: primaryAccentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    l10n.myDigitalPass,
                                    style: TextStyle(
                                      color: primaryAccentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: secondaryTextColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Services Section (الخدمات)
          Text(
            l10n.quickActions,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _ServiceCard(
                icon: Icons.directions_bus_filled_outlined,
                label: l10n.routesTitle,
                cardBgColor: cardBgColor,
                cardBorderColor: cardBorderColor,
                primaryAccentColor: primaryAccentColor,
                primaryTextColor: primaryTextColor,
                onTap: () => context.read<HomeNavCubit>().selectTab(1),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ServiceCard(
                icon: Icons.route_outlined,
                label: l10n.activeTrips,
                cardBgColor: cardBgColor,
                cardBorderColor: cardBorderColor,
                primaryAccentColor: primaryAccentColor,
                primaryTextColor: primaryTextColor,
                onTap: () => context.read<HomeNavCubit>().selectTab(2),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ServiceCard(
                icon: Icons.location_on_outlined,
                label: l10n.stationsTitle,
                cardBgColor: cardBgColor,
                cardBorderColor: cardBorderColor,
                primaryAccentColor: primaryAccentColor,
                primaryTextColor: primaryTextColor,
                onTap: () => context.read<HomeNavCubit>().selectTab(2),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ServiceCard(
                icon: Icons.notifications_none_outlined,
                label: l10n.notifications,
                cardBgColor: cardBgColor,
                cardBorderColor: cardBorderColor,
                primaryAccentColor: primaryAccentColor,
                primaryTextColor: primaryTextColor,
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.cardBgColor,
    required this.cardBorderColor,
    required this.primaryAccentColor,
    required this.primaryTextColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color primaryAccentColor;
  final Color primaryTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorderColor),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: primaryAccentColor,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
