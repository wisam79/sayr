import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/formatting.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/emergency/presentation/widgets/emergency_sos_button.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/map_widget.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_status_chip.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Driver view: trip lifecycle controls + live location streaming.
class DriverTripControlsPage extends StatefulWidget {
  /// Creates a [DriverTripControlsPage].
  const DriverTripControlsPage({required this.tripId, super.key});

  /// The active trip ID.
  final TripId tripId;

  @override
  State<DriverTripControlsPage> createState() => _DriverTripControlsPageState();
}

class _DriverTripControlsPageState extends State<DriverTripControlsPage> {
  geo.LocationSettings? _locationSettings;
  StreamSubscription<geo.Position>? _positionSubscription;
  Timer? _bleOtpTimer;
  String? _currentOtp;

  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: widget.tripId));
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _stopBleProximity();
    super.dispose();
  }

  String _generateOtp() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  void _startBleProximity(TripId tripId) {
    if (_bleOtpTimer != null) return;

    final bleService = sl<BleBeaconService>();
    final tripRepo = sl<TripRepository>();

    void updateOtp() async {
      final otp = _generateOtp();
      _currentOtp = otp;
      final expiresAt = DateTime.now().add(const Duration(seconds: 45));

      // Update database
      await tripRepo.updateBleOtp(
        tripId: tripId,
        otp: otp,
        expiresAt: expiresAt,
      );

      // Refresh advertising
      await bleService.startAdvertising(tripId: tripId, otp: otp);
    }

    // Initial trigger
    updateOtp();

    // Rotate OTP every 30 seconds
    _bleOtpTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => updateOtp());
  }

  void _stopBleProximity() {
    _bleOtpTimer?.cancel();
    _bleOtpTimer = null;
    _currentOtp = null;
    sl<BleBeaconService>().stopAdvertising();
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
      distanceFilter: 20,
    );

    _positionSubscription =
        geo.Geolocator.getPositionStream(locationSettings: _locationSettings)
            .listen(
      (position) {
        if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
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
                content: Text(state.failure.message ?? l10n.errorOccurred),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  state.failure.message ?? l10n.errorOccurred,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
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
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EmergencySosButton(tripId: tripId, routeId: routeId),
          );
        },
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
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
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
                                l10n.duration(formatDurationAr(trip.duration!)),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
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
    final l10n = AppLocalizations.of(context);
    final actions = validActions.where(_isVisible).toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    TripEvent? progressiveAction;
    for (final event in actions) {
      if (event != TripEvent.cancel) {
        progressiveAction = event;
        break;
      }
    }
    final hasCancel = actions.contains(TripEvent.cancel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progressiveAction != null)
          _buildSwipeButton(context, progressiveAction, l10n),
        if (progressiveAction != null && hasCancel)
          const SizedBox(height: AppSpacing.md),
        if (hasCancel) _buildCancelButton(context, l10n),
      ],
    );
  }

  Widget _buildSwipeButton(
    BuildContext context,
    TripEvent event,
    AppLocalizations l10n,
  ) {
    final Color color;
    if (event == TripEvent.arrive) {
      color = AppColors.secondary;
    } else if (event == TripEvent.start) {
      color = AppColors.primary;
    } else if (event == TripEvent.complete) {
      color = AppColors.success;
    } else {
      color = AppColors.primary;
    }

    return SwipeButton.expand(
      thumb: Icon(
        _icon(event),
        color: Colors.white,
      ),
      activeThumbColor: color,
      activeTrackColor: color.withValues(alpha: 0.1),
      child: Text(
        _label(event, l10n),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      onSwipe: () => onAction(_buildEvent(event)),
    );
  }

  Widget _buildCancelButton(BuildContext context, AppLocalizations l10n) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.error,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      onPressed: () => _confirmCancel(context, l10n),
      icon: const Icon(Icons.close, size: 20),
      label: Text(l10n.cancel),
    );
  }

  void _confirmCancel(BuildContext context, AppLocalizations l10n) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.cancelTripConfirm),
        content: Text(l10n.cancelTripConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.no),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed ?? false) {
        onAction(_buildEvent(TripEvent.cancel));
      }
    });
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

  String _label(TripEvent event, AppLocalizations l10n) {
    if (event == TripEvent.arrive) {
      return l10n.arrive;
    } else if (event == TripEvent.start) {
      return l10n.begin;
    } else if (event == TripEvent.complete) {
      return l10n.complete;
    } else if (event == TripEvent.cancel) {
      return l10n.cancel;
    } else {
      return event.name;
    }
  }

  IconData _icon(TripEvent event) {
    if (event == TripEvent.arrive) {
      return Icons.location_on;
    } else if (event == TripEvent.start) {
      return Icons.play_arrow;
    } else if (event == TripEvent.complete) {
      return Icons.check;
    } else if (event == TripEvent.cancel) {
      return Icons.close;
    } else {
      return Icons.help;
    }
  }
}
