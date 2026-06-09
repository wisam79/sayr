import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/route_details_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Page showing detailed information about a single route.
class RouteDetailsPage extends StatelessWidget {
  /// Creates a [RouteDetailsPage].
  const RouteDetailsPage({this.route, this.routeId, super.key});

  /// The route object if passed directly.
  final Route? route;

  /// The route ID to load dynamically.
  final RouteId? routeId;

  @override
  Widget build(BuildContext context) {
    if (route != null) {
      return _RouteDetailsBody(route: route!);
    }
    if (routeId != null) {
      return BlocProvider(
        create: (_) => RouteDetailsCubit(
          routeRepository: sl<RouteRepository>(),
        )..loadRoute(routeId!),
        child: _RouteDetailsContent(routeId: routeId),
      );
    }
    return const _RouteNotFound();
  }
}

class _RouteDetailsContent extends StatelessWidget {
  const _RouteDetailsContent({this.initialRoute, this.routeId})
      : assert(
          initialRoute != null || routeId != null,
          'Either initialRoute or routeId must be provided',
        );

  final Route? initialRoute;
  final RouteId? routeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RouteDetailsCubit, RouteDetailsState>(
      builder: (context, state) {
        if (state is RouteDetailsLoaded) {
          return _RouteDetailsBody(route: state.route);
        }
        if (state is RouteDetailsLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.routeDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is RouteDetailsError) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.routeDetails)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.failure.toLocalizedString(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (routeId != null)
                    ElevatedButton(
                      onPressed: () =>
                          context.read<RouteDetailsCubit>().loadRoute(routeId!),
                      child: Text(l10n.retry),
                    ),
                ],
              ),
            ),
          );
        }
        if (initialRoute != null) {
          return _RouteDetailsBody(route: initialRoute!);
        }
        return const _RouteNotFound();
      },
    );
  }
}

class _RouteDetailsBody extends StatelessWidget {
  const _RouteDetailsBody({required this.route});

  final Route route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(route.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${route.startLocation} → ${route.endLocation}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.attach_money,
                    color: AppColors.success,
                    label: l10n.price,
                    value: route.price.format(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.event_seat,
                    color: AppColors.primary,
                    label: l10n.availableSeats,
                    value: '${route.availableSeats} / ${route.capacity}',
                  ),
                  if (route.departureTime != null) ...[
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.schedule,
                      color: AppColors.primary,
                      label: l10n.departureTime,
                      value: route.departureTime!,
                    ),
                  ],
                  if (route.returnTime != null) ...[
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.access_time,
                      color: AppColors.primary,
                      label: l10n.returnTime,
                      value: route.returnTime!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.subscribe,
              onPressed: () => _showSubscriptionMethodSelector(context, route),
              icon: Icons.confirmation_number,
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionMethodSelector(BuildContext context, Route route) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.choosePaymentMethod,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.key, color: AppColors.primary),
                  ),
                  title: Text(l10n.activateLicense),
                  subtitle: Text(l10n.enterVoucherCode),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push('/activate-license', extra: route);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    child: const Icon(Icons.payment, color: AppColors.success),
                  ),
                  title: Text(l10n.paymentViaZainCash),
                  subtitle: Text(
                    l10n.directPaymentAmount(route.price.format()),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push(
                      '/payment/${route.id.value}/${route.price.inIQD}',
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(value),
    );
  }
}

class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeDetails)),
      body: Center(child: Text(l10n.routeNotFound)),
    );
  }
}
