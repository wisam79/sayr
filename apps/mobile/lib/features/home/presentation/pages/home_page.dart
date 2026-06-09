import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/locale_cubit.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/create_trip_dialog_cubit.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/routes_list_page.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/active_trips_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_status_chip.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Home page of the application, displaying different tabs based on role.
class HomePage extends StatelessWidget {
  /// Creates a [HomePage].
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

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<HomeNavCubit, int>(
          builder: (context, index) {
            return Text(
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
            );
          },
        ),
        actions: [
          if (!isDriver)
            BlocBuilder<HomeNavCubit, int>(
              builder: (context, index) {
                if (index != 0) return const SizedBox.shrink();
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_outlined),
                      tooltip: l10n.chats,
                      onPressed: () => context.push('/chats'),
                    ),
                    BlocBuilder<NotificationsBloc, NotificationsState>(
                      buildWhen: (prev, curr) =>
                          prev.maybeWhen(
                            loaded: (a, b) => b,
                            orElse: () => 0,
                          ) !=
                          curr.maybeWhen(
                            loaded: (a, b) => b,
                            orElse: () => 0,
                          ),
                      builder: (context, state) {
                        final unread = state.maybeWhen(
                          loaded: (_, count) => count,
                          orElse: () => 0,
                        );
                        return IconButton(
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_outlined),
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
                        );
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<HomeNavCubit, int>(
        builder: (context, index) {
          return IndexedStack(
            index: index,
            children: isDriver
                ? [
                    _DriverHomeTab(
                      onOpenTrips: () =>
                          context.read<HomeNavCubit>().selectTab(1),
                    ),
                    const _DriverTripsTab(),
                    const _ProfileTab(),
                  ]
                : [
                    const _HomeTab(),
                    const RoutesListPage(showAppBar: false),
                    const ActiveTripsPage(showAppBar: false),
                    const MySubscriptionsPage(showAppBar: false),
                    const _ProfileTab(),
                  ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<HomeNavCubit, int>(
        builder: (context, index) {
          return BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => context.read<HomeNavCubit>().selectTab(i),
            items: isDriver
                ? [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home),
                      label: l10n.homeTitle,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.directions_bus_outlined),
                      activeIcon: const Icon(Icons.directions_bus),
                      label: l10n.activeTrips,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline),
                      activeIcon: const Icon(Icons.person),
                      label: l10n.profile,
                    ),
                  ]
                : [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_outlined),
                      activeIcon: const Icon(Icons.home),
                      label: l10n.homeTitle,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.directions_bus_outlined),
                      activeIcon: const Icon(Icons.directions_bus),
                      label: l10n.routesTitle,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.map_outlined),
                      activeIcon: const Icon(Icons.map),
                      label: l10n.activeTrips,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.confirmation_number_outlined),
                      activeIcon: const Icon(Icons.confirmation_number),
                      label: l10n.mySubscriptions,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline),
                      activeIcon: const Icon(Icons.person),
                      label: l10n.profile,
                    ),
                  ],
          );
        },
      ),
    );
  }
}

// ─── Student Tabs ────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return Text(
                  l10n.helloUser(state.user.displayName),
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<SubscriptionsBloc, SubscriptionsState>(
            builder: (context, state) {
              if (state is SubscriptionsLoaded) {
                final active = state.subscriptions
                    .where((s) => s.isActive && !s.isExpired)
                    .toList();
                if (active.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                l10n.activeSubscription,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          EmptyState(
                            icon: Icons.confirmation_number_outlined,
                            title: l10n.noActiveSubscription,
                            subtitle: l10n.getSubscription,
                            action: PrimaryButton(
                              label: l10n.activateLicense,
                              onPressed: () =>
                                  context.push('/activate-license'),
                              icon: Icons.add,
                              isExpanded: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    title: Text(l10n.activeSubscription),
                    subtitle: Text(
                      l10n.activeSubscriptionCount(active.length),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/subscriptions'),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.directions_bus, color: AppColors.primary),
              title: Text(l10n.browseRoutes),
              subtitle: Text(l10n.browseRoutesDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/routes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Driver Tabs ─────────────────────────────────────────────────────────────

class _DriverHomeTab extends StatelessWidget {
  const _DriverHomeTab({required this.onOpenTrips});

  final VoidCallback onOpenTrips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return Text(
                  l10n.helloUser(state.user.displayName),
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle, color: AppColors.primary),
              title: Text(l10n.createNewTrip),
              subtitle: Text(l10n.createNewTripDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCreateTripDialog(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.directions_bus, color: AppColors.success),
              title: Text(l10n.myActiveTrips),
              subtitle: Text(l10n.myActiveTripsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.read<TrackingBloc>().add(
                      const TrackingLoadActiveTrips(),
                    );
                onOpenTrips();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTripDialog(BuildContext context) async {
    final trip = await showDialog<core.Trip>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => CreateTripDialogCubit(
          routeRepository: sl<core.RouteRepository>(),
        )..loadRoutes(),
        child: const _CreateTripDialog(),
      ),
    );
    if (trip != null && context.mounted) {
      context.go('/driver-trip/${trip.id.value}');
    }
  }
}

class _CreateTripDialog extends StatelessWidget {
  const _CreateTripDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CreateTripDialogCubit, CreateTripDialogState>(
      builder: (context, state) {
        return AlertDialog(
          title: Text(l10n.createTrip),
          content: SizedBox(
            width: double.maxFinite,
            child: _buildContent(context, state),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: state.selectedRoute == null || state.isSubmitting
                  ? null
                  : () => _createTrip(context, state),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.create),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, CreateTripDialogState state) {
    final l10n = AppLocalizations.of(context);
    if (state.loadingRoutes) {
      return const SizedBox(
        height: 96,
        child: LoadingWidget(),
      );
    }
    if (state.routes.isEmpty) {
      return EmptyState(
        icon: Icons.route_outlined,
        title: state.failure?.toLocalizedString(context) ?? l10n.noDriverRoutes,
        subtitle: l10n.activeRouteRequired,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<core.Route>(
          // ignore: deprecated_member_use — DropdownButtonFormField has no non-deprecated null-safe override
          value: state.selectedRoute,
          decoration: InputDecoration(
            labelText: l10n.routeTitle,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final route in state.routes)
              DropdownMenuItem(
                value: route,
                child: Text(route.title),
              ),
          ],
          onChanged: (route) =>
              context.read<CreateTripDialogCubit>().selectRoute(route),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: Text(l10n.tripTime),
          subtitle: Text(
            _formatScheduledAt(
              state.scheduledAt ??
                  DateTime.now().add(const Duration(minutes: 10)),
            ),
          ),
          trailing: const Icon(Icons.edit_calendar),
          onTap: () => _pickScheduledAt(context, state),
        ),
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.failure!.toLocalizedString(context),
            style: const TextStyle(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Future<void> _createTrip(
    BuildContext context,
    CreateTripDialogState state,
  ) async {
    final route = state.selectedRoute;
    if (route == null) return;

    final scheduledAt =
        state.scheduledAt ?? DateTime.now().add(const Duration(minutes: 10));

    if (!scheduledAt.isAfter(DateTime.now())) {
      context.read<CreateTripDialogCubit>().setError(
            const core.ValidationFailure(message: 'trip_time_must_be_future'),
          );
      return;
    }

    context.read<CreateTripDialogCubit>().setSubmitting(isSubmitting: true);

    final result = await sl<core.TripRepository>().createTrip(
      routeId: route.id,
      scheduledAt: scheduledAt,
    );

    if (!context.mounted) return;
    result.fold(
      (failure) => context.read<CreateTripDialogCubit>().setError(failure),
      (trip) => Navigator.of(context).pop(trip),
    );
  }

  Future<void> _pickScheduledAt(
    BuildContext context,
    CreateTripDialogState state,
  ) async {
    final initial =
        state.scheduledAt ?? DateTime.now().add(const Duration(minutes: 10));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;

    context.read<CreateTripDialogCubit>().updateScheduledAt(
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
  }

  String _formatScheduledAt(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}/${local.month}/${local.day} - $hour:$minute';
  }
}

class _DriverTripsTab extends StatefulWidget {
  const _DriverTripsTab();

  @override
  State<_DriverTripsTab> createState() => _DriverTripsTabState();
}

class _DriverTripsTabState extends State<_DriverTripsTab> {
  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(const TrackingLoadActiveTrips());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TrackingBloc, TrackingState>(
      builder: (context, state) {
        if (state is TrackingLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TrackingActiveTripsLoaded) {
          if (state.trips.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TrackingBloc>()
                    .add(const TrackingLoadActiveTrips());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.directions_bus_outlined,
                        title: l10n.noActiveTrips,
                        subtitle: l10n.noTripsYet,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TrackingBloc>().add(const TrackingLoadActiveTrips());
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.lg,
              ),
              itemCount: state.trips.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final trip = state.trips[index];
                return _DriverTripCard(trip: trip);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  const _DriverTripCard({required this.trip});

  final core.Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor;

    return InkWell(
      onTap: () {
        context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: trip.id));
        context.push('/driver-trip/${trip.id.value}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: statusColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          child: Icon(
                            _statusIcon,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                trip.status.localizedName(l10n),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formattedTime,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (trip.status) {
      case core.TripStatus.scheduled:
        return Colors.orange[700]!;
      case core.TripStatus.driverWaiting:
        return Colors.blue[600]!;
      case core.TripStatus.inTransit:
        return AppColors.primary;
      case core.TripStatus.completed:
        return AppColors.success;
      case core.TripStatus.absent:
        return AppColors.error;
      case core.TripStatus.cancelled:
        return AppColors.textMuted;
    }
  }

  IconData get _statusIcon {
    switch (trip.status) {
      case core.TripStatus.scheduled:
        return Icons.schedule;
      case core.TripStatus.driverWaiting:
        return Icons.hourglass_top;
      case core.TripStatus.inTransit:
        return Icons.directions_bus;
      case core.TripStatus.completed:
        return Icons.check_circle;
      case core.TripStatus.absent:
        return Icons.cancel;
      case core.TripStatus.cancelled:
        return Icons.block;
    }
  }

  String get _formattedTime {
    final hour = trip.scheduledAt.hour.toString().padLeft(2, '0');
    final minute = trip.scheduledAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }
        return _ProfileView(user: state.user);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user});

  final core.User user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(
                  context.watch<LocaleCubit>().state.languageCode == 'ar'
                      ? l10n.arabic
                      : l10n.english,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final current = context.read<LocaleCubit>().state;
                  context.read<LocaleCubit>().setLocale(
                        current.languageCode == 'ar'
                            ? const Locale('en')
                            : const Locale('ar'),
                      );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  l10n.logout,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}
