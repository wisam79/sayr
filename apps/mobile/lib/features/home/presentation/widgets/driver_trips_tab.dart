import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_status_chip.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DriverTripsTab extends StatefulWidget {
  const DriverTripsTab({super.key});

  @override
  State<DriverTripsTab> createState() => _DriverTripsTabState();
}

class _DriverTripsTabState extends State<DriverTripsTab> {
  @override
  void initState() {
    super.initState();
    context.read<TrackingBloc>().add(const TrackingLoadActiveTrips());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TrackingBloc, TrackingState>(
      builder: (context, state) {
        if (state is TrackingLoading) {
          return const _SkeletonLoading();
        }
        if (state is TrackingActiveTripsLoaded) {
          if (state.trips.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TrackingBloc>()
                    .add(const TrackingLoadActiveTrips());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.directions_bus_outlined,
                        title: l10n.noActiveTrips,
                        subtitle: l10n.noTripsYet,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<TrackingBloc>()
                  .add(const TrackingLoadActiveTrips());
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.lg,
              ),
              itemCount: state.trips.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final trip = state.trips[index];
                return DriverTripCard(trip: trip);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.lg,
        ),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const ListTile(
          leading: Bone.circle(size: 40),
          title: Bone.text(),
          subtitle: Padding(
            padding: EdgeInsetsDirectional.only(top: 4),
            child: Bone.text(),
          ),
        ),
      ),
    );
  }
}

class DriverTripCard extends StatelessWidget {
  const DriverTripCard({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor;

    return Semantics(
      button: true,
      label: '${trip.status.localizedName(l10n)} - $_formattedTime',
      child: InkWell(
        onTap: () {
          context.read<TrackingBloc>().add(TrackingWatchTrip(tripId: trip.id));
          context.push('/driver-trip/${trip.id.value}');
        },
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        onTap: () {},
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        child: Icon(
                          _statusIcon,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trip.status.localizedName(l10n),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formattedTime,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Color get _statusColor => trip.status.color;

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
