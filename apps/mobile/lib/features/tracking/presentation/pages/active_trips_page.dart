import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../l10n/app_localizations.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';
import '../widgets/map_widget.dart';

/// Student view: shows all active trips on a map.
class ActiveTripsPage extends StatefulWidget {
  const ActiveTripsPage({super.key, this.showAppBar = true});
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
      appBar: widget.showAppBar ? AppBar(title: Text(l10n.activeTrips)) : null,
      body: BlocBuilder<TrackingBloc, TrackingState>(
        builder: (context, state) {
          if (state is TrackingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TrackingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.failure.message ?? l10n.error,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: l10n.retry,
                    onPressed: () => context
                        .read<TrackingBloc>()
                        .add(const TrackingLoadActiveTrips()),
                  ),
                ],
              ),
            );
          }

          if (state is TrackingActiveTripsLoaded) {
            return _buildMapWithTrips(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMapWithTrips(TrackingActiveTripsLoaded state) {
    final markers = state.trips
        .where((t) => t.lastLocation != null)
        .map((trip) => SayrMarker(
              position: LatLng(
                trip.lastLocation!.latitude,
                trip.lastLocation!.longitude,
              ),
              data: trip,
            ))
        .toList();

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: SayrMap(markers: markers),
        ),
        Expanded(
          flex: 2,
          child: state.trips.isEmpty
              ? const EmptyState(
                  icon: Icons.directions_bus_outlined,
                  title: 'لا توجد رحلات نشطة',
                  subtitle: 'لا توجد رحلات حالياً على خطوطك',
                )
              : _TripList(trips: state.trips),
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
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor.withAlpha(20),
          child: Icon(_statusIcon, color: _statusColor, size: 20),
        ),
        title: Text(
          trip.status.displayNameAr,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          _formattedTime,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: trip.id));
          context.push('/trip/${trip.id.value}');
        },
      ),
    );
  }

  Color get _statusColor {
    switch (trip.status) {
      case TripStatus.scheduled:
        return Colors.orange;
      case TripStatus.driverWaiting:
        return Colors.blue;
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
