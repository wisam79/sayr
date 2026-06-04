import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

import '../../../../core/sayr_flash.dart';
import '../bloc/emergency_bloc.dart';
import '../bloc/emergency_state.dart';

/// Floating SOS button. Tapping shows a confirmation dialog before
/// dispatching [EmergencyTriggered].
class EmergencySosButton extends StatelessWidget {
  const EmergencySosButton({
    required this.tripId,
    required this.routeId,
    super.key,
  });

  final TripId tripId;
  final RouteId routeId;

  Future<void> _onPressed(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('تنبيه طوارئ'),
        content: const Text(
          'هل تريد فعلاً إرسال تنبيه طوارئ؟ سيتم إخطار المسؤولين بموقعك الحالي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('نعم، أرسل'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final Coordinates? location = await _captureLocation();
    if (location == null) {
      if (!context.mounted) return;
      SayrFlash.error(context, 'تعذر تحديد موقعك. حاول مجدداً.');
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
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmergencyBloc, EmergencyState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is EmergencyActive) {
          SayrFlash.error(
            context,
            'تم إرسال تنبيه الطوارئ. سيتم التواصل معك قريباً.',
          );
        } else if (state is EmergencyFailed) {
          SayrFlash.error(
            context,
            state.failure.message ?? 'فشل إرسال تنبيه الطوارئ',
          );
        }
      },
      builder: (context, state) {
        final bool isActive = state is EmergencyActive;
        final bool isSending = state is EmergencySending;
        return FloatingActionButton.extended(
          backgroundColor: isActive ? AppColors.error : AppColors.error,
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
            isActive ? 'تم الإرسال' : (isSending ? 'جارٍ الإرسال...' : 'طوارئ'),
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
