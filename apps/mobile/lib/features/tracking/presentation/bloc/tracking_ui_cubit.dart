import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/osrm_service.dart';
import 'package:sayr_mobile/di/di.dart';

/// UI-only state for the trip tracking view.
class TrackingUiState extends Equatable {
  const TrackingUiState({
    this.ratingShown = false,
    this.isFetchingRoute = false,
    this.routePoints,
    this.loadedRouteId,
  });

  /// Whether the rating sheet has already been shown.
  final bool ratingShown;

  /// Whether the OSRM route is currently being fetched.
  final bool isFetchingRoute;

  /// The decoded route polyline points (or straight-line fallback).
  final List<LatLng>? routePoints;

  /// Which route's path is currently cached in [routePoints].
  final RouteId? loadedRouteId;

  @override
  List<Object?> get props => [ratingShown, isFetchingRoute, routePoints, loadedRouteId];

  TrackingUiState copyWith({
    bool? ratingShown,
    bool? isFetchingRoute,
    List<LatLng>? Function()? routePoints,
    RouteId? Function()? loadedRouteId,
  }) {
    return TrackingUiState(
      ratingShown: ratingShown ?? this.ratingShown,
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
      routePoints: routePoints != null ? routePoints() : this.routePoints,
      loadedRouteId: loadedRouteId != null ? loadedRouteId() : this.loadedRouteId,
    );
  }

  static final initial = TrackingUiState();
}

/// Manages ephemeral UI state for the trip tracking view.
///
/// Holds the OSRM route path, rating-guard flag, and trip details loading
/// in a single [TrackingUiState]. This replaces the `setState` + raw
/// field pattern that previously lived in `_TripTrackingViewState`.
class TrackingUiCubit extends Cubit<TrackingUiState> {
  TrackingUiCubit() : super(TrackingUiState.initial);

  /// Attempts to fetch the driving route between [start] and [end].
  /// Falls back to a straight line on error (OSRM timeout, etc.).
  Future<void> fetchRoutePath({
    required Coordinates start,
    required Coordinates end,
    required RouteId routeId,
  }) async {
    if (state.routePoints != null && state.loadedRouteId == routeId) return;
    if (state.isFetchingRoute) return;

    emit(state.copyWith(isFetchingRoute: true));

    try {
      final points = await sl<OsrmService>().getRoute(
        LatLng(start.latitude, start.longitude),
        LatLng(end.latitude, end.longitude),
      );
      emit(state.copyWith(
        isFetchingRoute: false,
        routePoints: () => points,
        loadedRouteId: () => routeId,
      ));
    } catch (_) {
      emit(state.copyWith(
        isFetchingRoute: false,
        routePoints: () => [
          LatLng(start.latitude, start.longitude),
          LatLng(end.latitude, end.longitude),
        ],
        loadedRouteId: () => routeId,
      ));
    }
  }

  /// Guards the rating sheet so it only opens once per trip.
  void markRatingShown() => emit(state.copyWith(ratingShown: true));

  /// Resets for a new trip.
  void reset() => emit(TrackingUiState.initial);
}
