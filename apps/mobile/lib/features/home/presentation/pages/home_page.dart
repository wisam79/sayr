import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../di/di.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/locale_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../../routes/presentation/pages/routes_list_page.dart';
import '../../../subscriptions/presentation/bloc/subscriptions_bloc.dart';
import '../../../subscriptions/presentation/bloc/subscriptions_event.dart';
import '../../../subscriptions/presentation/bloc/subscriptions_state.dart';
import '../../../subscriptions/presentation/pages/my_subscriptions_page.dart';
import '../../../tracking/presentation/bloc/tracking_bloc.dart';
import '../../../tracking/presentation/bloc/tracking_event.dart';
import '../../../tracking/presentation/bloc/tracking_state.dart';
import '../../../tracking/presentation/pages/active_trips_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

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
        title: Text(
          isDriver
              ? (switch (_currentIndex) {
                  0 => l10n.appTitle,
                  1 => l10n.activeTrips,
                  2 => l10n.profile,
                  _ => l10n.appTitle,
                })
              : (switch (_currentIndex) {
                  0 => l10n.appTitle,
                  1 => l10n.routesTitle,
                  2 => l10n.activeTrips,
                  3 => l10n.mySubscriptions,
                  4 => l10n.profile,
                  _ => l10n.appTitle,
                }),
        ),
        actions: [
          if (!isDriver && _currentIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              tooltip: l10n.chats,
              onPressed: () => context.push('/chats'),
            ),
            BlocBuilder<NotificationsBloc, NotificationsState>(
              buildWhen: (prev, curr) =>
                  prev.maybeWhen(loaded: (a, b) => b, orElse: () => 0) !=
                  curr.maybeWhen(loaded: (a, b) => b, orElse: () => 0),
              builder: (context, state) {
                final int unread = state.maybeWhen(
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
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: isDriver
            ? [
                _DriverHomeTab(
                  onOpenTrips: () => setState(() => _currentIndex = 1),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
                  'مرحباً، ${state.user.displayName}',
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
                      '${active.length} ${active.length == 1 ? 'اشتراك' : 'اشتراكات'} نشطة',
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
              title: const Text('تصفح الخطوط'),
              subtitle: const Text('اعثر على خط يناسبك'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return Text(
                  'مرحباً، ${state.user.displayName}',
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
              title: const Text('إنشاء رحلة جديدة'),
              subtitle: const Text('ابدأ رحلة على خط مسجل لديك'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCreateTripDialog(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.directions_bus, color: AppColors.success),
              title: const Text('رحلاتي النشطة'),
              subtitle: const Text('عرض وإدارة رحلاتك الجارية'),
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
      builder: (_) => const _CreateTripDialog(),
    );
    if (trip != null && context.mounted) {
      context.go('/driver-trip/${trip.id.value}');
    }
  }
}

class _CreateTripDialog extends StatefulWidget {
  const _CreateTripDialog();

  @override
  State<_CreateTripDialog> createState() => _CreateTripDialogState();
}

class _CreateTripDialogState extends State<_CreateTripDialog> {
  late final Future<List<core.Route>> _routesFuture;
  core.Route? _selectedRoute;
  DateTime _scheduledAt = DateTime.now().add(const Duration(minutes: 10));
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _routesFuture = _loadRoutes();
  }

  Future<List<core.Route>> _loadRoutes() async {
    final result = await sl<core.RouteRepository>().getMyDriverRoutes();
    return result.fold(
      (failure) => throw Exception(failure.message ?? 'فشل تحميل الخطوط'),
      (routes) => routes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنشاء رحلة جديدة'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<core.Route>>(
          future: _routesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 96,
                child: LoadingWidget(),
              );
            }
            if (snapshot.hasError) {
              return Text(
                snapshot.error.toString(),
                style: const TextStyle(color: AppColors.error),
              );
            }

            final routes = snapshot.data ?? const <core.Route>[];
            if (routes.isEmpty) {
              return const EmptyState(
                icon: Icons.route_outlined,
                title: 'لا توجد خطوط مرتبطة بحسابك',
                subtitle: 'يجب توفر خط نشط قبل إنشاء رحلة.',
              );
            }

            _selectedRoute ??= routes.first;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<core.Route>(
                  value: _selectedRoute,
                  decoration: const InputDecoration(
                    labelText: 'الخط',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final route in routes)
                      DropdownMenuItem(
                        value: route,
                        child: Text(route.title),
                      ),
                  ],
                  onChanged: (route) => setState(() {
                    _selectedRoute = route;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('وقت الرحلة'),
                  subtitle: Text(_formatScheduledAt(_scheduledAt)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickScheduledAt,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed:
              _selectedRoute == null || _isSubmitting ? null : _createTrip,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إنشاء'),
        ),
      ],
    );
  }

  Future<void> _createTrip() async {
    final route = _selectedRoute;
    if (route == null) return;

    if (!_scheduledAt.isAfter(DateTime.now())) {
      setState(() {
        _errorMessage = 'وقت الرحلة يجب أن يكون في المستقبل';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await sl<core.TripRepository>().createTrip(
      routeId: route.id,
      scheduledAt: _scheduledAt,
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isSubmitting = false;
        _errorMessage = failure.message ?? 'فشل إنشاء الرحلة';
      }),
      (trip) => Navigator.of(context).pop(trip),
    );
  }

  Future<void> _pickScheduledAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _errorMessage = null;
    });
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
                    child: const Center(
                      child: EmptyState(
                        icon: Icons.directions_bus_outlined,
                        title: 'لا توجد رحلات نشطة',
                        subtitle: 'لم تقم بإنشاء أي رحلة بعد',
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
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              itemCount: state.trips.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final trip = state.trips[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.directions_bus,
                          color: AppColors.primary, size: 20),
                    ),
                    title: Text(trip.status.displayNameAr),
                    subtitle: Text(
                      '${trip.scheduledAt.hour.toString().padLeft(2, '0')}:'
                      '${trip.scheduledAt.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/driver-trip/${trip.id.value}'),
                  ),
                );
              },
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('اضغط للتحديث'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<TrackingBloc>()
                      .add(const TrackingLoadActiveTrips());
                },
                child: const Text('تحديث'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared Profile Tab ──────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                state.user.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                state.user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
                child: Text(
                  state.user.role.isDriver ? 'سائق' : 'طالب',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.language),
                      subtitle: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? l10n.arabic
                            : l10n.english,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLanguageDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: AppColors.error,
                      ),
                      title: Text(
                        l10n.logout,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      onTap: () {
                        context
                            .read<AuthBloc>()
                            .add(const AuthLogoutRequested());
                        context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.chooseLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'ar',
                groupValue: current,
                title: Text(l10n.arabic),
                onChanged: (value) => _setLanguage(context, value),
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: current,
                title: Text(l10n.english),
                onChanged: (value) => _setLanguage(context, value),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setLanguage(BuildContext context, String? languageCode) {
    if (languageCode == null) return;
    context.read<LocaleCubit>().setLocale(Locale(languageCode));
    Navigator.of(context).pop();
  }
}
