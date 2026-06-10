import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/map_widget.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_status_chip.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Student view: shows all active trips on a map.
class ActiveTripsPage extends StatefulWidget {
  /// Creates an [ActiveTripsPage].
  const ActiveTripsPage({super.key, this.showAppBar = true});

  /// Whether to show the app bar on this page.
  final bool showAppBar;

  @override
  State<ActiveTripsPage> createState() => _ActiveTripsPageState();
}

class _ActiveTripsPageState extends State<ActiveTripsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(const TrackingLoadActiveTrips());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                l10n.activeTrips,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
            )
          : null,
      extendBodyBehindAppBar: widget.showAppBar,
      body: BlocBuilder<TrackingBloc, TrackingState>(
        builder: (context, state) {
          if (state is TrackingLoading) {
            return const _SkeletonLoading();
          }

          if (state is TrackingError) {
            return AppErrorWidget(
              message: state.failure.toLocalizedString(context),
              title: l10n.error,
              retryLabel: l10n.retry,
              onRetry: () => context
                  .read<TrackingBloc>()
                  .add(const TrackingLoadActiveTrips()),
            );
          }

          if (state is TrackingActiveTripsLoaded) {
            return _buildMapWithTrips(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMapWithTrips(
    BuildContext context,
    TrackingActiveTripsLoaded state,
  ) {
    final l10n = AppLocalizations.of(context);

    if (state.trips.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: l10n.noActiveTrips,
        subtitle: l10n.noTripsYet,
        action: PrimaryButton(
          label: l10n.browseRoutes,
          icon: Icons.search,
          onPressed: () {
            context.read<HomeNavCubit>().selectTab(1);
          },
        ),
      );
    }

    final markers = state.trips
        .where((t) => t.lastLocation != null)
        .map(
          (trip) => SayrMarker(
            id: trip.id.value,
            position: LatLng(
              trip.lastLocation!.latitude,
              trip.lastLocation!.longitude,
            ),
            data: trip,
          ),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TrackingBloc>().add(const TrackingLoadActiveTrips());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height -
              kToolbarHeight -
              MediaQuery.of(context).padding.top,
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: SayrMap(
                  markers: markers,
                  useCluster: true,
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _TripList(trips: state.trips),
                ),
              ),
            ],
          ),
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
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            color: Theme.of(context).cardColor,
            child: const Center(child: Bone.circle(size: 48)),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                ListTile(
                  leading: Bone.circle(size: 40),
                  title: Bone.text(),
                  subtitle: Padding(
                    padding: EdgeInsetsDirectional.only(top: 4),
                    child: Bone.text(),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: Bone.circle(size: 40),
                  title: Bone.text(),
                  subtitle: Padding(
                    padding: EdgeInsetsDirectional.only(top: 4),
                    child: Bone.text(),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: Bone.circle(size: 40),
                  title: Bone.text(),
                  subtitle: Padding(
                    padding: EdgeInsetsDirectional.only(top: 4),
                    child: Bone.text(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.lg,
      ),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _TripCard(trip: trip);
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor;

    final routesState = context.watch<RoutesBloc>().state;
    var routeTitle = l10n.routeNotFound;
    if (routesState is RoutesLoaded) {
      final route = routesState.routes
          .cast<Route?>()
          .firstWhere((r) => r?.id == trip.routeId, orElse: () => null);
      if (route != null) {
        routeTitle = route.title;
      }
    }

    return GlassCard(
      onTap: () {
        context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: trip.id));
        context.push('/trip/${trip.id.value}');
      },
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      borderRadius: 16,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Accent Status Bar
            Container(
              width: 6,
              color: statusColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Status Icon
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

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            routeTitle,
                            style: (Theme.of(context).textTheme.titleMedium ??
                                    const TextStyle())
                                .copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
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
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  trip.status.localizedName(l10n),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right Arrow/Chevron
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
    );
  }

  Color get _statusColor => trip.status.color;

  IconData get _statusIcon {
    switch (trip.status) {
      case TripStatus.scheduled:
        return Icons.schedule;
      case TripStatus.driverWaiting:
        return Icons.hourglass_top;
      case TripStatus.inTransit:
        return Icons.directions_bus;
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.absent:
        return Icons.cancel;
      case TripStatus.cancelled:
        return Icons.block;
    }
  }

  String get _formattedTime {
    final hour = trip.scheduledAt.hour.toString().padLeft(2, '0');
    final minute = trip.scheduledAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
