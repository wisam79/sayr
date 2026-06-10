import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:logger/logger.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/formatting.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/emergency/presentation/widgets/emergency_sos_button.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/driver_action_buttons.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/map_widget.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_status_chip.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Driver view: trip lifecycle controls + live location streaming.
class DriverTripControlsPage extends StatefulWidget {
  /// Creates a [DriverTripControlsPage].
  const DriverTripControlsPage({
    required this.tripId,
    this.trackingBloc,
    super.key,
  });

  /// The active trip ID.
  final TripId tripId;

  /// Optional [TrackingBloc] for testing.
  final TrackingBloc? trackingBloc;

  @override
  State<DriverTripControlsPage> createState() => _DriverTripControlsPageState();
}

class _DriverTripControlsPageState extends State<DriverTripControlsPage> {
  final Logger _logger = Logger();
  late final TrackingBloc _trackingBloc;
  geo.LocationSettings? _locationSettings;
  StreamSubscription<geo.Position>? _positionSubscription;
  geo.Position? _lastSentPosition;
  DateTime? _lastSentTime;

  @override
  void initState() {
    super.initState();
    _trackingBloc = widget.trackingBloc ??
        TrackingBloc(tripRepository: sl<TripRepository>());
    if (widget.trackingBloc == null) {
      _trackingBloc.add(TrackingWatchTrip(tripId: widget.tripId));
    }
  }

  @override
  void dispose() {
    _trackingBloc.close();
    _stopLocationTracking();
    _stopBleProximity();
    super.dispose();
  }

  void _startBleProximity(TripId tripId) {
    sl<BleBeaconService>().startRotatingOtpAdvertising(
      tripId: tripId,
      tripRepository: sl<TripRepository>(),
      logger: _logger,
    );
  }

  void _stopBleProximity() {
    sl<BleBeaconService>().stopRotatingOtpAdvertising();
  }

  Future<void> _startLocationTracking(TripId tripId) async {
    final l10n = AppLocalizations.of(context);
    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      final requested = await geo.Geolocator.requestPermission();
      if (requested == geo.LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionRequired)),
          );
        }
        return;
      }
    }

    _locationSettings = const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
    );

    _positionSubscription =
        geo.Geolocator.getPositionStream(locationSettings: _locationSettings)
            .listen(
      (position) {
        if (!mounted) return;

        final now = DateTime.now();
        var shouldUpdate = false;

        if (_lastSentPosition == null || _lastSentTime == null) {
          shouldUpdate = true;
        } else {
          final distance = geo.Geolocator.distanceBetween(
            _lastSentPosition!.latitude,
            _lastSentPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          // Update if moved more than 20 meters
          if (distance >= 20) {
            shouldUpdate = true;
          }

          // Update if heading changes by more than 15 degrees
          // Only evaluate when moving (>1 m/s) to prevent static GPS jitter from triggering updates
          if (position.heading != 0 &&
              _lastSentPosition!.heading != 0 &&
              position.speed > 1) {
            final hDiff =
                (position.heading - _lastSentPosition!.heading).abs() % 360;
            final actualDiff = hDiff > 180 ? 360 - hDiff : hDiff;
            if (actualDiff >= 15) {
              shouldUpdate = true;
            }
          }

          // Fallback: Send a heartbeat update every 3 minutes if stationary
          if (now.difference(_lastSentTime!) >= const Duration(minutes: 3)) {
            shouldUpdate = true;
          }
        }

        if (shouldUpdate) {
          _lastSentPosition = position;
          _lastSentTime = now;
          context.read<TrackingBloc>().add(
                TrackingUpdateLocation(
                  tripId: tripId,
                  latitude: position.latitude,
                  longitude: position.longitude,
                ),
              );
        }
      },
    );
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationSettings = null;
    _lastSentPosition = null;
    _lastSentTime = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _trackingBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.tripControl,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        body: BlocConsumer<TrackingBloc, TrackingState>(
          listener: (context, state) {
            if (state is TrackingDriverActive) {
              if (state.isTrackingLocation) {
                if (_positionSubscription == null) {
                  _startLocationTracking(state.trip.id);
                }
              }
              final status = state.trip.status;
              if (status == TripStatus.driverWaiting ||
                  status == TripStatus.inTransit) {
                _startBleProximity(state.trip.id);
              } else {
                _stopBleProximity();
              }
            } else if (state is TrackingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.toLocalizedString(context)),
                  backgroundColor: AppColors.error,
                ),
              );
            } else {
              _stopLocationTracking();
              _stopBleProximity();
            }
          },
          builder: (context, state) {
            if (state is TrackingDriverActive) {
              return _buildDriverView(state);
            }
            if (state is TrackingError) {
              final previous = state.previousState;
              if (previous is TrackingDriverActive) {
                return _buildDriverView(previous);
              }
              return AppErrorWidget(
                message: state.failure.toLocalizedString(context),
                title: l10n.error,
                retryLabel: l10n.retry,
                onRetry: () => _trackingBloc.add(
                  TrackingWatchTrip(tripId: widget.tripId),
                ),
              );
            }
            return const Center(child: LoadingWidget());
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
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 12),
              child: EmergencySosButton(tripId: tripId, routeId: routeId),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverView(TrackingDriverActive state) {
    final l10n = AppLocalizations.of(context);
    final trip = state.trip;
    final cameraPosition = CameraPosition(
      target: state.currentLocation != null
          ? LatLng(
              state.currentLocation!.latitude,
              state.currentLocation!.longitude,
            )
          : SayrMap.defaultCenter,
      zoom: 15,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: SayrMap(
            initialCameraPosition: cameraPosition,
            myLocationEnabled: true,
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: SafeArea(
            top: false,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar decoration
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Status row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TripStatusChip(status: trip.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Active duration
                        if (trip.duration != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  l10n.duration(
                                    formatDurationAr(
                                      l10n,
                                      trip.duration!,
                                    ),
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Controls
                        DriverActionButtons(
                          validActions: state.validActions,
                          onAction: (event) {
                            context.read<TrackingBloc>().add(event);
                          },
                          tripId: trip.id,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
