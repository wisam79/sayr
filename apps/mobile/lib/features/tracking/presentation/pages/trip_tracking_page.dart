import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as geo;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/formatting.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/emergency/presentation/widgets/emergency_sos_button.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_event.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_state.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_ui_cubit.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/trip_details_cubit.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/location_tile.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/map_widget.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/rating_sheet.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_mock_loader.dart';
import 'package:sayr_mobile/features/tracking/presentation/widgets/trip_status_chip.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Student view: live tracking of a single trip on a map.
class TripTrackingPage extends StatelessWidget {
  const TripTrackingPage({required this.tripId, super.key});

  final TripId tripId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TripDetailsCubit(
            routeRepository: sl<RouteRepository>(),
            driverRepository: sl<DriverRepository>(),
            ratingRepository: sl<RatingRepository>(),
          ),
        ),
        BlocProvider(create: (_) => TrackingUiCubit()),
      ],
      child: _TripTrackingView(tripId: tripId),
    );
  }
}

class _TripTrackingView extends StatefulWidget {
  const _TripTrackingView({required this.tripId});

  final TripId tripId;

  @override
  State<_TripTrackingView> createState() => _TripTrackingViewState();
}

class _TripTrackingViewState extends State<_TripTrackingView> {
  late final TrackingBloc _trackingBloc;

  @override
  void initState() {
    super.initState();
    _trackingBloc = context.read<TrackingBloc>();
    _trackingBloc.add(TrackingWatchTrip(tripId: widget.tripId));
  }

  @override
  void dispose() {
    _trackingBloc.add(const TrackingStopWatching());
    context.read<TrackingUiCubit>().reset();
    super.dispose();
  }

  void _loadRouteDetails(RouteId routeId, DriverId driverId) {
    context.read<TripDetailsCubit>().loadTripDetails(
          routeId: routeId,
          driverId: driverId,
          tripId: widget.tripId,
        );
  }

  void _checkAndShowRating(BuildContext context, Trip trip) {
    final uiCubit = context.read<TrackingUiCubit>();
    if (uiCubit.state.ratingShown) return;
    final detailsState = context.read<TripDetailsCubit>().state;
    if (detailsState is TripDetailsLoaded && detailsState.tripRating == null) {
      uiCubit.markRatingShown();
      _showRatingBottomSheet(
        context,
        trip,
        detailsState.driverProfile?.fullName ?? '',
      );
    }
  }

  void _showRatingBottomSheet(
    BuildContext context,
    Trip trip,
    String driverName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<TripDetailsCubit>(),
          child: RatingSheet(trip: trip, driverName: driverName),
        );
      },
    );
  }

  Future<void> _fetchRoutePathIfNeeded(Trip trip) async {
    final start = trip.routeStartLocation;
    final end = trip.routeEndLocation;
    if (start != null && end != null) {
      await context.read<TrackingUiCubit>().fetchRoutePath(
            start: start,
            end: end,
            routeId: trip.routeId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripTracking),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: MultiBlocListener(
        listeners: [
          BlocListener<TrackingBloc, TrackingState>(
            listener: (context, state) {
              if (state is TrackingTripWatching) {
                _loadRouteDetails(state.trip.routeId, state.trip.driverId);
                if (state.trip.status == TripStatus.completed) {
                  _checkAndShowRating(context, state.trip);
                }
                _fetchRoutePathIfNeeded(state.trip);
              } else if (state is TrackingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.failure.message ?? l10n.error),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
          BlocListener<TripDetailsCubit, TripDetailsState>(
            listener: (context, state) {
              final trackingState = context.read<TrackingBloc>().state;
              if (state is TripDetailsLoaded &&
                  trackingState is TrackingTripWatching) {
                if (trackingState.trip.status == TripStatus.completed) {
                  _checkAndShowRating(context, trackingState.trip);
                }
              }
            },
          ),
        ],
        child: BlocBuilder<TrackingBloc, TrackingState>(
          builder: (context, state) {
            if (state is TrackingTripWatching) {
              return _TrackingView(state: state);
            }

            if (state is TrackingError) {
              final previous = state.previousState;
              if (previous is TrackingTripWatching) {
                return _TrackingView(state: previous);
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.failure.message ?? l10n.error,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            return const Skeletonizer(
              child: TripMockLoader(),
            );
          },
        ),
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
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 12),
            child: EmergencySosButton(tripId: tripId, routeId: routeId),
          );
        },
      ),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView({required this.state});

  final TrackingTripWatching state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          id: 'driver_location',
          position: LatLng(
            state.driverLocation!.latitude,
            state.driverLocation!.longitude,
          ),
        ),
    ];

    String? etaText;
    if (hasLocation && trip.routeStartLocation != null) {
      final startLoc = trip.routeStartLocation!;
      final driverLoc = state.driverLocation!;

      final distance = const geo.Distance().as(
        geo.LengthUnit.Meter,
        geo.LatLng(startLoc.latitude, startLoc.longitude),
        geo.LatLng(driverLoc.latitude, driverLoc.longitude),
      );

      final distanceKm = (distance / 1000).toStringAsFixed(1);
      final minutes = (distance / 500).round();

      etaText = l10n.etaDistance(distanceKm, '$minutes');
    }

    return BlocBuilder<TrackingUiCubit, TrackingUiState>(
      builder: (context, uiState) {
        return Stack(
          children: [
            Positioned.fill(
              child: SayrMap(
                initialCameraPosition: cameraPosition,
                markers: markers,
                routePoints: uiState.routePoints,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: BlocBuilder<TripDetailsCubit, TripDetailsState>(
                        builder: (context, detailsState) {
                          final route = detailsState is TripDetailsLoaded
                              ? detailsState.route
                              : null;
                          final driver = detailsState is TripDetailsLoaded
                              ? detailsState.driver
                              : null;
                          final profile = detailsState is TripDetailsLoaded
                              ? detailsState.driverProfile
                              : null;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  TripStatusChip(status: trip.status),
                                  const Spacer(),
                                  if (trip.duration != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        formatDurationAr(l10n, trip.duration!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (etaText != null) ...[
                                _EtaCard(text: etaText),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              LocationTile(
                                icon: Icons.circle,
                                color: AppColors.primary,
                                label: route?.startLocation ?? l10n.start,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: SizedBox(
                                  height: 12,
                                  child: VerticalDivider(
                                    width: 1,
                                    thickness: 1.5,
                                  ),
                                ),
                              ),
                              LocationTile(
                                icon: Icons.location_on,
                                color: AppColors.error,
                                label: route?.endLocation ?? l10n.destination,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Divider(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.08),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (profile != null && driver != null) ...[
                                _DriverSection(
                                  profile: profile,
                                  driver: driver,
                                  route: route,
                                  trip: trip,
                                ),
                              ] else ...[
                                if (!hasLocation &&
                                    trip.status == TripStatus.scheduled)
                                  Text(
                                    l10n.waitingForDriver,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static LatLng _centerFromTrip(Trip trip) {
    if (trip.routeStartLat != null && trip.routeStartLng != null) {
      return LatLng(trip.routeStartLat!, trip.routeStartLng!);
    }
    return SayrMap.defaultCenter;
  }
}

class _EtaCard extends StatelessWidget {
  const _EtaCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverSection extends StatelessWidget {
  const _DriverSection({
    required this.profile,
    required this.driver,
    required this.route,
    required this.trip,
  });

  final User profile;
  final Driver driver;
  final Route? route;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: profile.avatarUrl != null
                  ? CachedNetworkImageProvider(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profile.fullName ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (driver.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${driver.vehicleModel} • ${driver.vehiclePlate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    driver.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: l10n.callDriver,
                icon: Icons.phone,
                onPressed: () async {
                  final phone = profile.phone;
                  if (phone != null && phone.isNotEmpty) {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SecondaryButton(
                label: l10n.chatDriver,
                icon: Icons.chat_bubble_outline,
                onPressed: () async {
                  final chatRepo = sl<ChatRepository>();
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);

                  final conversationResult =
                      await chatRepo.getOrCreateConversation(
                    routeId: route!.id,
                    driverUserId: driver.userId,
                  );
                  conversationResult.fold(
                    (failure) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            failure.message ?? l10n.failedToStartChat,
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
                    (conversation) {
                      router.push('/chat/${conversation.id.value}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
