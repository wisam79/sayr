import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geo;
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

/// Driver view: trip lifecycle controls + live location streaming.
class DriverTripControlsPage extends StatefulWidget {
  const DriverTripControlsPage({required this.tripId, super.key});

  final TripId tripId;

  @override
  State<DriverTripControlsPage> createState() => _DriverTripControlsPageState();
}

class _DriverTripControlsPageState extends State<DriverTripControlsPage> {
  geo.LocationSettings? _locationSettings;
  StreamSubscription<geo.Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: widget.tripId));
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  Future<void> _startLocationTracking(TripId tripId) async {
    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      final requested = await geo.Geolocator.requestPermission();
      if (requested == geo.LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب السماح بالوصول للموقع')),
          );
        }
        return;
      }
    }

    _locationSettings = const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 20,
    );

    _positionSubscription =
        geo.Geolocator.getPositionStream(locationSettings: _locationSettings!)
            .listen(
      (position) {
        if (mounted) {
          context.read<TrackingBloc>().add(TrackingUpdateLocation(
                tripId: tripId,
                latitude: position.latitude,
                longitude: position.longitude,
              ));
        }
      },
    );
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationSettings = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحكم بالرحلة')),
      body: BlocConsumer<TrackingBloc, TrackingState>(
        listener: (context, state) {
          if (state is TrackingDriverActive && state.isTrackingLocation) {
            if (_positionSubscription == null) {
              _startLocationTracking(state.trip.id);
            }
          } else {
            _stopLocationTracking();
          }
        },
        builder: (context, state) {
          if (state is TrackingDriverActive) {
            return _buildDriverView(state);
          }
          if (state is TrackingError) {
            return Center(
              child: Text(
                state.failure.message ?? 'حدث خطأ',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: BlocBuilder<TrackingBloc, TrackingState>(
        buildWhen: (prev, curr) {
          final prevId = prev.maybeWhen(
            driverActive: (t, _, __, ___, ____) => t.id,
            orElse: () => null,
          );
          final currId = curr.maybeWhen(
            driverActive: (t, _, __, ___, ____) => t.id,
            orElse: () => null,
          );
          return prevId != currId;
        },
        builder: (context, state) {
          final tripId = state.maybeWhen(
            driverActive: (t, _, __, ___, ____) => t.id,
            orElse: () => null,
          );
          final routeId = state.maybeWhen(
            driverActive: (t, _, __, ___, ____) => t.routeId,
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

  Widget _buildDriverView(TrackingDriverActive state) {
    final trip = state.trip;
    final cameraPosition = CameraPosition(
      target: state.currentLocation != null
          ? LatLng(state.currentLocation!.latitude, state.currentLocation!.longitude)
          : SayrMap.defaultCenter,
      zoom: 15,
    );

    return Column(
      children: [
        Expanded(
          child: SayrMap(
            initialCameraPosition: cameraPosition,
            myLocationEnabled: true,
          ),
        ),
        Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              TripStatusChip(status: trip.status),
              const SizedBox(height: AppSpacing.md),
              if (trip.duration != null)
                Text(
                  'المدة: ${_formatDuration(trip.duration!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.lg),
              _ActionButtons(
                validActions: state.validActions,
                onAction: (event) {
                  context.read<TrackingBloc>().add(event);
                },
                tripId: trip.id,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) => formatDurationAr(d);
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.validActions,
    required this.onAction,
    required this.tripId,
  });

  final List<TripEvent> validActions;
  final void Function(TrackingEvent) onAction;
  final TripId tripId;

  @override
  Widget build(BuildContext context) {
    final actions = validActions.where(_isVisible).toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions.map((event) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: PrimaryButton(
              label: _label(event),
              icon: _icon(event),
              isLoading: false,
              onPressed: () => onAction(_buildEvent(event)),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isVisible(TripEvent event) {
    return event == TripEvent.arrive ||
        event == TripEvent.start ||
        event == TripEvent.complete ||
        event == TripEvent.cancel;
  }

  TrackingEvent _buildEvent(TripEvent event) {
    if (event == TripEvent.arrive) {
      return TrackingDriverArrive(tripId: tripId);
    } else if (event == TripEvent.start) {
      return TrackingDriverStart(tripId: tripId);
    } else if (event == TripEvent.complete) {
      return TrackingDriverComplete(tripId: tripId);
    } else {
      return TrackingDriverCancel(tripId: tripId);
    }
  }

  String _label(TripEvent event) {
    switch (event) {
      case TripEvent.arrive:
        return 'وصلت';
      case TripEvent.start:
        return 'ابدأ';
      case TripEvent.complete:
        return 'أكمل';
      case TripEvent.cancel:
        return 'إلغاء';
      default:
        return event.name;
    }
  }

  IconData _icon(TripEvent event) {
    switch (event) {
      case TripEvent.arrive:
        return Icons.location_on;
      case TripEvent.start:
        return Icons.play_arrow;
      case TripEvent.complete:
        return Icons.check;
      case TripEvent.cancel:
        return Icons.close;
      default:
        return Icons.help;
    }
  }
}
