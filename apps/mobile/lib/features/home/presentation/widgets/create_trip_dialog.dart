import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart' as core;
import 'package:sayr_mobile/core/extensions/failure_extension.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/create_trip_dialog_cubit.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class CreateTripDialog extends StatelessWidget {
  const CreateTripDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CreateTripDialogCubit, CreateTripDialogState>(
      builder: (context, state) {
        return SayrDialog(
          title: l10n.createTrip,
          headerIcon: Icons.route_outlined,
          primaryLabel: l10n.create,
          onPrimaryPressed: (state.selectedRoute == null ||
                  state.isSubmitting ||
                  state.loadingRoutes)
              ? null
              : () => _createTrip(context, state),
          isPrimaryLoading: state.isSubmitting,
          secondaryLabel: l10n.cancel,
          onSecondaryPressed: () => Navigator.of(context).pop(),
          content: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, CreateTripDialogState state) {
    final l10n = AppLocalizations.of(context);
    if (state.loadingRoutes) {
      return const SizedBox(
        height: 96,
        child: LoadingWidget(),
      );
    }
    if (state.routes.isEmpty) {
      return EmptyState(
        icon: Icons.route_outlined,
        title: state.failure?.toLocalizedString(context) ?? l10n.noDriverRoutes,
        subtitle: l10n.activeRouteRequired,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<core.Route>(
          // ignore: deprecated_member_use
          value: state.selectedRoute,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.routeTitle,
            border: const OutlineInputBorder(),
          ),
          selectedItemBuilder: (BuildContext context) {
            return state.routes.map<Widget>((core.Route route) {
              return Text(
                route.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }).toList();
          },
          items: [
            for (final route in state.routes)
              DropdownMenuItem(
                value: route,
                child: Text(
                  route.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
          onChanged: (route) =>
              context.read<CreateTripDialogCubit>().selectRoute(route),
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: () => _pickScheduledAt(context, state),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.tripTime,
              prefixIcon:
                  const Icon(Icons.event, color: AppColors.textSecondary),
              suffixIcon: const Icon(
                Icons.edit_calendar,
                color: AppColors.textSecondary,
              ),
              border: const OutlineInputBorder(),
            ),
            child: Text(
              _formatScheduledAt(
                state.scheduledAt ??
                    DateTime.now().add(const Duration(minutes: 10)),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.failure!.toLocalizedString(context),
            style: const TextStyle(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Future<void> _createTrip(
    BuildContext context,
    CreateTripDialogState state,
  ) async {
    final route = state.selectedRoute;
    if (route == null) return;

    final scheduledAt =
        state.scheduledAt ?? DateTime.now().add(const Duration(minutes: 10));

    if (!scheduledAt.isAfter(DateTime.now())) {
      context.read<CreateTripDialogCubit>().setError(
            const core.ValidationFailure(message: 'trip_time_must_be_future'),
          );
      return;
    }

    context.read<CreateTripDialogCubit>().setSubmitting(isSubmitting: true);

    final result = await sl<core.TripRepository>().createTrip(
      routeId: route.id,
      scheduledAt: scheduledAt,
    );

    if (!context.mounted) return;
    result.fold(
      (failure) => context.read<CreateTripDialogCubit>().setError(failure),
      (trip) => Navigator.of(context).pop(trip),
    );
  }

  Future<void> _pickScheduledAt(
    BuildContext context,
    CreateTripDialogState state,
  ) async {
    final initial =
        state.scheduledAt ?? DateTime.now().add(const Duration(minutes: 10));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;

    context.read<CreateTripDialogCubit>().updateScheduledAt(
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
  }

  String _formatScheduledAt(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}/${local.month}/${local.day} - $hour:$minute';
  }
}
