import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:logger/logger.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

final Logger _emergencyLogger = Logger();

/// Floating SOS button. Tapping shows a confirmation dialog before
/// dispatching [EmergencyTriggered].
class EmergencySosButton extends StatelessWidget {
  /// Creates an [EmergencySosButton] with the given [tripId] and [routeId].
  const EmergencySosButton({
    required this.tripId,
    required this.routeId,
    super.key,
  });

  /// The active trip ID.
  final TripId tripId;

  /// The active route ID.
  final RouteId routeId;

  Future<void> _onPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.sendEmergency),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.emergencyConfirmMessage),
            const SizedBox(height: AppSpacing.lg),
            SwipeButton.expand(
              thumb: const Icon(
                Icons.double_arrow_rounded,
                color: Colors.white,
              ),
              activeThumbColor: AppColors.error,
              activeTrackColor: AppColors.error.withValues(alpha: 0.1),
              child: Text(
                l10n.sendEmergency,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onSwipe: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final location = await _captureLocation();
    if (location == null) {
      if (!context.mounted) return;
      SayrFlash.error(context, l10n.locationUnavailable);
      return;
    }

    if (!context.mounted) return;
    context.read<EmergencyBloc>().add(
          EmergencyTriggered(
            tripId: tripId,
            routeId: routeId,
            location: location,
          ),
        );
  }

  Future<Coordinates?> _captureLocation() async {
    try {
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        final requested = await geo.Geolocator.requestPermission();
        if (requested == geo.LocationPermission.denied) {
          return null;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        return null;
      }

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e, st) {
      _emergencyLogger.w(
        'Failed to capture location for SOS; proceeding without coords',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<EmergencyBloc, EmergencyState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is EmergencyActive) {
          SayrFlash.error(context, l10n.emergencySentMessage);
        } else if (state is EmergencyFailed) {
          SayrFlash.error(
            context,
            state.failure.toLocalizedString(context),
          );
        }
      },
      builder: (context, state) {
        final isActive = state is EmergencyActive;
        final isSending = state is EmergencySending;
        return FloatingActionButton.extended(
          backgroundColor: AppColors.error,
          onPressed: isSending
              ? null
              : isActive
                  ? () => context
                      .read<EmergencyBloc>()
                      .add(const EmergencyCancelled())
                  : () => _onPressed(context),
          icon: isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isActive ? Icons.check : Icons.sos,
                  color: Colors.white,
                ),
          label: Text(
            isActive ? l10n.sent : (isSending ? l10n.sending : l10n.sos),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
