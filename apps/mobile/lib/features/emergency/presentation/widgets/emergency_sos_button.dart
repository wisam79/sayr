import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/core/sayr_flash.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Floating SOS button. Tapping shows a confirmation dialog before
/// dispatching [EmergencyTriggered].
class EmergencySosButton extends StatelessWidget {
  /// Creates an [EmergencySosButton] with the given [tripId], [routeId], and [driverId].
  const EmergencySosButton({
    required this.tripId,
    required this.routeId,
    required this.driverId,
    super.key,
  });

  /// The active trip ID.
  final TripId tripId;

  /// The active route ID.
  final RouteId routeId;

  /// The driver's ID, used to fetch the driver's phone number for fallback contact.
  final DriverId driverId;

  Future<void> _onPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => SayrDialog(
        title: l10n.sendEmergency,
        headerIcon: Icons.warning_amber_rounded,
        headerIconColor: AppColors.error,
        secondaryLabel: l10n.cancel,
        onSecondaryPressed: () => Navigator.of(ctx).pop(false),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.emergencyConfirmMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: SwipeButton.expand(
                thumb: const Icon(
                  Icons.double_arrow_rounded,
                  color: Colors.white,
                ),
                activeThumbColor: AppColors.error,
                activeTrackColor: Colors.transparent,
                child: Text(
                  l10n.sendEmergency,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onSwipe: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final location = await _captureLocation();

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
        if (requested == geo.LocationPermission.denied ||
            requested == geo.LocationPermission.deniedForever) {
          return null;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        return null;
      }

      try {
        final position = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        return Coordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        final lastKnown = await geo.Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return Coordinates(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          );
        }
        rethrow;
      }
    } catch (e, st) {
      sl<Talker>().warning(
        'Failed to capture location for SOS; sending alert with null coordinates',
        e,
        st,
      );
      return null;
    }
  }

  /// Fetches the driver's phone number via [DriverRepository] and launches
  /// the phone dialer. Falls back gracefully if the phone number is
  /// unavailable.
  Future<void> _callDriver(BuildContext context) async {
    try {
      final driverRepo = sl<DriverRepository>();
      final driverResult = await driverRepo.getDriverById(driverId);

      final phone = await driverResult.fold(
        (_) async => null,
        (driver) async {
          final profileResult =
              await driverRepo.getDriverProfile(driver.userId);
          return profileResult.fold((_) => null, (user) => user.phone);
        },
      );

      if (phone != null && phone.isNotEmpty) {
        final phoneUri = Uri(scheme: 'tel', path: phone);
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
          return;
        }
      }

      // Phone unavailable — log and show a message if still mounted.
      sl<Talker>().warning(
        'EmergencySosButton: Driver phone number not available for driverId=$driverId',
      );
      if (context.mounted) {
        SayrFlash.error(
          context,
          AppLocalizations.of(context).error,
        );
      }
    } catch (e, st) {
      sl<Talker>().error(
        'EmergencySosButton: Failed to call driver',
        e,
        st,
      );
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

          showDialog<void>(
            context: context,
            builder: (BuildContext ctx) => SayrDialog(
              title: l10n.sos,
              headerIcon: Icons.phone_callback_rounded,
              headerIconColor: AppColors.error,
              primaryLabel: l10n.callDriver,
              secondaryLabel: l10n.cancel,
              onSecondaryPressed: () => Navigator.of(ctx).pop(),
              onPrimaryPressed: () async {
                Navigator.of(ctx).pop();
                await _callDriver(context);
              },
              content: Text(
                l10n.emergencyFailedOffline,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isActive = state is EmergencyActive ||
            (state is EmergencyFailed && state.activeReport != null);
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
