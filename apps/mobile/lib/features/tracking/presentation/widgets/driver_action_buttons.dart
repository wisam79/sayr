import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

/// Action buttons (swipe + cancel) for the driver trip controls.
class DriverActionButtons extends StatelessWidget {
  /// Creates a [DriverActionButtons].
  const DriverActionButtons({
    required this.validActions,
    required this.onAction,
    required this.tripId,
    super.key,
  });

  /// List of valid trip events from the FSM.
  final List<TripEvent> validActions;

  /// Callback when an action is triggered.
  final void Function(TrackingEvent) onAction;

  /// The current trip ID.
  final TripId tripId;

  @override
  Widget build(BuildContext context) {
    final actions =
        validActions.where((e) => e != TripEvent.markAbsent).toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    final progressiveAction = actions.firstWhere(
      (e) => e != TripEvent.cancel,
      orElse: () => TripEvent.cancel,
    );
    final hasCancel = actions.contains(TripEvent.cancel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progressiveAction != TripEvent.cancel)
          _SwipeButton(
            event: progressiveAction,
            onAction: onAction,
            tripId: tripId,
          ),
        if (progressiveAction != TripEvent.cancel && hasCancel)
          const SizedBox(height: AppSpacing.md),
        if (hasCancel) _CancelButton(onAction: onAction, tripId: tripId),
      ],
    );
  }
}

class _SwipeButton extends StatelessWidget {
  const _SwipeButton({
    required this.event,
    required this.onAction,
    required this.tripId,
  });

  final TripEvent event;
  final void Function(TrackingEvent) onAction;
  final TripId tripId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _colorFor(event);

    return SwipeButton.expand(
      thumb: Icon(_iconFor(event), color: Colors.white),
      activeThumbColor: color,
      activeTrackColor: color.withValues(alpha: 0.1),
      child: Text(
        _labelFor(event, l10n),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      onSwipe: () => onAction(_buildEvent(event, l10n)),
    );
  }

  TrackingEvent _buildEvent(TripEvent event, AppLocalizations l10n) =>
      switch (event) {
        TripEvent.arrive => TrackingDriverArrive(tripId: tripId),
        TripEvent.start => TrackingDriverStart(
            tripId: tripId,
            notificationTitle: l10n.tripTrackingActiveTitle,
            notificationText: l10n.tripTrackingActiveText,
          ),
        TripEvent.complete => TrackingDriverComplete(tripId: tripId),
        _ => TrackingDriverCancel(tripId: tripId),
      };
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({
    required this.onAction,
    required this.tripId,
  });

  final void Function(TrackingEvent) onAction;
  final TripId tripId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      builder: (BuildContext ctx) => SayrDialog(
        title: l10n.cancelTripConfirm,
        subtitle: l10n.cancelTripConfirmMessage,
        headerIcon: Icons.warning_amber_rounded,
        headerIconColor: AppColors.error,
        primaryLabel: l10n.yes,
        onPrimaryPressed: () => Navigator.of(ctx).pop(true),
        secondaryLabel: l10n.no,
        onSecondaryPressed: () => Navigator.of(ctx).pop(false),
      ),
    ).then((confirmed) {
      if (confirmed ?? false) {
        onAction(TrackingDriverCancel(tripId: tripId));
      }
    });
  }
}

Color _colorFor(TripEvent event) => switch (event) {
      TripEvent.arrive => AppColors.secondary,
      TripEvent.start => AppColors.primary,
      TripEvent.complete => AppColors.success,
      _ => AppColors.primary,
    };

IconData _iconFor(TripEvent event) => switch (event) {
      TripEvent.arrive => Icons.location_on,
      TripEvent.start => Icons.play_arrow,
      TripEvent.complete => Icons.check,
      TripEvent.cancel => Icons.close,
      _ => Icons.help,
    };

String _labelFor(TripEvent event, AppLocalizations l10n) => switch (event) {
      TripEvent.arrive => l10n.arrive,
      TripEvent.start => l10n.begin,
      TripEvent.complete => l10n.complete,
      TripEvent.cancel => l10n.cancel,
      _ => event.name,
    };
