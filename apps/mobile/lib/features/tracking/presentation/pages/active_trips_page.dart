import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/map_widget.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_status_chip.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

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
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TrackingError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.failure.message ?? l10n.error,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.retry,
                      onPressed: () => context
                          .read<TrackingBloc>()
                          .add(const TrackingLoadActiveTrips()),
                    ),
                  ],
                ),
              ),
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
    final markers = state.trips
        .where((t) => t.lastLocation != null)
        .map(
          (trip) => SayrMarker(
            position: LatLng(
              trip.lastLocation!.latitude,
              trip.lastLocation!.longitude,
            ),
            data: trip,
          ),
        )
        .toList();

    return Column(
      children: [
        Expanded(
          flex: 4,
          child: SayrMap(markers: markers),
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
            child: state.trips.isEmpty
                ? EmptyState(
                    icon: Icons.directions_bus_outlined,
                    title: l10n.noActiveTrips,
                    subtitle: l10n.noTripsYet,
                  )
                : _TripList(trips: state.trips),
          ),
        ),
      ],
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

    return InkWell(
      onTap: () {
        context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: trip.id));
        context.push('/trip/${trip.id.value}');
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
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (trip.status) {
      case TripStatus.scheduled:
        return Colors.orange[700]!;
      case TripStatus.driverWaiting:
        return Colors.blue[600]!;
      case TripStatus.inTransit:
        return AppColors.primary;
      case TripStatus.completed:
        return AppColors.success;
      case TripStatus.absent:
        return AppColors.error;
      case TripStatus.cancelled:
        return AppColors.textMuted;
    }
  }

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
