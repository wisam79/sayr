import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/driver_home_tab.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/driver_trips_tab.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/profile_view.dart';
import 'package:sayr_mobile/features/home/presentation/widgets/student_home_tab.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/routes_list_page.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/active_trips_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeNavCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionsBloc>().add(const SubscriptionsLoadRequested());
    context.read<NotificationsBloc>().add(const NotificationsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDriver = context.select<AuthBloc, bool>(
      (bloc) =>
          bloc.state is AuthAuthenticated &&
          (bloc.state as AuthAuthenticated).user.role.isDriver,
    );

    return BlocBuilder<HomeNavCubit, int>(
      builder: (context, index) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            context.read<HomeNavCubit>().selectTab(0);
          },
          child: Scaffold(
            extendBody: true,
            appBar: AppBar(
              title: Text(
                isDriver
                    ? (switch (index) {
                        0 => l10n.appTitle,
                        1 => l10n.activeTrips,
                        2 => l10n.profile,
                        _ => l10n.appTitle,
                      })
                    : (switch (index) {
                        0 => l10n.appTitle,
                        1 => l10n.routesTitle,
                        2 => l10n.activeTrips,
                        3 => l10n.mySubscriptions,
                        4 => l10n.profile,
                        _ => l10n.appTitle,
                      }),
              ),
              actions: [
                if (index == 0) _HeaderActions(l10n: l10n),
              ],
            ),
            body: IndexedStack(
              index: index,
              children: isDriver
                  ? [
                      DriverHomeTab(
                        onOpenTrips: () =>
                            context.read<HomeNavCubit>().selectTab(1),
                      ),
                      const DriverTripsTab(),
                      const ProfileTab(),
                    ]
                  : [
                      const StudentHomeTab(),
                      const RoutesListPage(showAppBar: false),
                      const ActiveTripsPage(showAppBar: false),
                      const MySubscriptionsPage(showAppBar: false),
                      const ProfileTab(),
                    ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.95)
                        : AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark.withValues(alpha: 0.5)
                          : AppColors.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: NavigationBar(
                      height: 64,
                      selectedIndex: index,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysHide,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      indicatorColor: Colors.transparent,
                      onDestinationSelected: (i) =>
                          context.read<HomeNavCubit>().selectTab(i),
                      destinations: isDriver
                          ? [
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.home_outlined,
                                  selectedIcon: Icons.home_rounded,
                                  isSelected: index == 0,
                                ),
                                label: l10n.homeTitle,
                              ),
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.route_outlined,
                                  selectedIcon: Icons.route_rounded,
                                  isSelected: index == 1,
                                ),
                                label: l10n.activeTrips,
                              ),
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.person_outline_rounded,
                                  selectedIcon: Icons.person_rounded,
                                  isSelected: index == 2,
                                ),
                                label: l10n.profile,
                              ),
                            ]
                          : [
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.home_outlined,
                                  selectedIcon: Icons.home_rounded,
                                  isSelected: index == 0,
                                ),
                                label: l10n.homeTitle,
                              ),
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.route_outlined,
                                  selectedIcon: Icons.route_rounded,
                                  isSelected: index == 1,
                                ),
                                label: l10n.routesTitle,
                              ),
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.map_outlined,
                                  selectedIcon: Icons.map_rounded,
                                  isSelected: index == 2,
                                ),
                                label: l10n.activeTrips,
                              ),
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.local_activity_outlined,
                                  selectedIcon: Icons.local_activity_rounded,
                                  isSelected: index == 3,
                                ),
                                label: l10n.mySubscriptions,
                              ),
                              NavigationDestination(
                                icon: _AnimatedNavIcon(
                                  icon: Icons.person_outline_rounded,
                                  selectedIcon: Icons.person_rounded,
                                  isSelected: index == 4,
                                ),
                                label: l10n.profile,
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.message_square),
          tooltip: l10n.chats,
          onPressed: () => context.push('/chats'),
        ),
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
                    const Icon(LucideIcons.bell),
                    if (unread > 0)
                      PositionedDirectional(
                        top: -2,
                        end: -2,
                        child: Container(
                          padding: const EdgeInsetsDirectional.all(4),
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
      ],
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  const _AnimatedNavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.white : AppColors.primary;
    final inactiveColor =
        isDark ? AppColors.textMuted : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: isSelected
              ? Icon(
                  selectedIcon,
                  key: const ValueKey('selected'),
                  color: activeColor,
                  size: 26,
                )
              : Icon(
                  icon,
                  key: const ValueKey('unselected'),
                  color: inactiveColor,
                  size: 24,
                ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 5 : 0,
          height: isSelected ? 5 : 0,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
