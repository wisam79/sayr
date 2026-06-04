import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../core/formatting.dart';
import '../../../emergency/presentation/widgets/emergency_sos_button.dart';
import '../bloc/tracking_bloc.dart';
import '../bloc/tracking_event.dart';
import '../bloc/tracking_state.dart';
import '../widgets/map_widget.dart';
import '../widgets/trip_status_chip.dart';

/// Student view: live tracking of a single trip on a map.
class TripTrackingPage extends StatefulWidget {
  const TripTrackingPage({required this.tripId, super.key});

  final TripId tripId;

  @override
  State<TripTrackingPage> createState() => _TripTrackingPageState();
}

class _TripTrackingPageState extends State<TripTrackingPage> {
  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: widget.tripId));
  }

  @override
  void dispose() {
    context.read<TrackingBloc>().add(const TrackingStopWatching());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الرحلة')),
      body: BlocBuilder<TrackingBloc, TrackingState>(
        builder: (context, state) {
          if (state is TrackingTripWatching) {
            return _buildTrackingView(state);
          }

          if (state is TrackingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.failure.message ?? 'حدث خطأ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: BlocBuilder<TrackingBloc, TrackingState>(
        buildWhen: (prev, curr) {
          final prevId = prev.maybeWhen(
            tripWatching: (t, _, __) => t.id,
            orElse: () => null,
          );
          final currId = curr.maybeWhen(
            tripWatching: (t, _, __) => t.id,
            orElse: () => null,
          );
          return prevId != currId;
        },
        builder: (context, state) {
          final tripId = state.maybeWhen(
            tripWatching: (t, _, __) => t.id,
            orElse: () => null,
          );
          final routeId = state.maybeWhen(
            tripWatching: (t, _, __) => t.routeId,
            orElse: () => null,
          );
          if (tripId == null || routeId == null) {
            return const SizedBox.shrink();
          }
          return EmergencySosButton(tripId: tripId, routeId: routeId);
        },
      ),
    );
  }

  Widget _buildTrackingView(TrackingTripWatching state) {
    final trip = state.trip;
    final hasLocation = state.driverLocation != null;

    final cameraPosition = CameraPosition(
      target: hasLocation
          ? LatLng(
              state.driverLocation!.latitude,
              state.driverLocation!.longitude,
            )
          : _centerFromTrip(trip),
      zoom: hasLocation ? 15 : 13,
    );

    final markers = <SayrMarker>[
      if (hasLocation)
        SayrMarker(
          position: LatLng(
            state.driverLocation!.latitude,
            state.driverLocation!.longitude,
          ),
        ),
    ];

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: SayrMap(
            initialCameraPosition: cameraPosition,
            markers: markers,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TripStatusChip(status: trip.status),
                    const Spacer(),
                    if (trip.duration != null)
                      Text(
                        _formatDuration(trip.duration!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (trip.routeStartLat != null && trip.routeStartLng != null)
                  _LocationTile(
                    icon: Icons.circle,
                    color: AppColors.primary,
                    label: trip.routeStartLat.toString(),
                  ),
                if (trip.routeEndLat != null && trip.routeEndLng != null)
                  _LocationTile(
                    icon: Icons.location_on,
                    color: AppColors.error,
                    label: trip.routeEndLat.toString(),
                  ),
                if (!hasLocation && trip.status == TripStatus.scheduled)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.lg),
                    child: Text(
                      'في انتظار السائق...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LatLng _centerFromTrip(Trip trip) {
    if (trip.routeStartLat != null && trip.routeStartLng != null) {
      return LatLng(trip.routeStartLat!, trip.routeStartLng!);
    }
    return SayrMap.defaultCenter;
  }

  String _formatDuration(Duration d) => formatDurationAr(d);
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
