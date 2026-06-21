import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/di/di.dart';

/// UI-only state for the trip tracking view.
class TrackingUiState extends Equatable {
  const TrackingUiState({
    this.ratingShown = false,
    this.isFetchingRoute = false,
    this.routePoints,
    this.loadedRouteId,
    this.isApproximate = false,
    this.distanceKm,
    this.etaMinutes,
  });

  /// Whether the rating sheet has already been shown.
  final bool ratingShown;

  /// Whether the route is currently being fetched.
  final bool isFetchingRoute;

  /// The decoded route polyline points (or straight-line fallback).
  final List<LatLng>? routePoints;

  /// Which route's path is currently cached in [routePoints].
  final RouteId? loadedRouteId;

  /// Whether the current route points are a fallback straight-line approximation.
  final bool isApproximate;

  /// Calculated distance in kilometers to the target.
  final double? distanceKm;

  /// Calculated ETA in minutes to the target.
  final int? etaMinutes;

  @override
  List<Object?> get props => [
        ratingShown,
        isFetchingRoute,
        routePoints,
        loadedRouteId,
        isApproximate,
        distanceKm,
        etaMinutes,
      ];

  TrackingUiState copyWith({
    bool? ratingShown,
    bool? isFetchingRoute,
    List<LatLng>? Function()? routePoints,
    RouteId? Function()? loadedRouteId,
    bool? isApproximate,
    double? Function()? distanceKm,
    int? Function()? etaMinutes,
  }) {
    return TrackingUiState(
      ratingShown: ratingShown ?? this.ratingShown,
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
      routePoints: routePoints != null ? routePoints() : this.routePoints,
      loadedRouteId:
          loadedRouteId != null ? loadedRouteId() : this.loadedRouteId,
      isApproximate: isApproximate ?? this.isApproximate,
      distanceKm: distanceKm != null ? distanceKm() : this.distanceKm,
      etaMinutes: etaMinutes != null ? etaMinutes() : this.etaMinutes,
    );
  }

  static const initial = TrackingUiState();
}

/// Manages ephemeral UI state for the trip tracking view.
///
/// Holds the OSRM route path, rating-guard flag, and computed ETA/distance.
class TrackingUiCubit extends Cubit<TrackingUiState> {
  TrackingUiCubit() : super(TrackingUiState.initial);

  /// Updates the computed ETA and distance using coordinates distance logic.
  void updateEta({
    required Coordinates? driverLocation,
    required Trip trip,
  }) {
    if (driverLocation == null) {
      emit(
        state.copyWith(
          distanceKm: () => null,
          etaMinutes: () => null,
        ),
      );
      return;
    }

    final targetLoc = (trip.status == TripStatus.inTransit)
        ? trip.routeEndLocation
        : trip.routeStartLocation;

    if (targetLoc == null) {
      emit(
        state.copyWith(
          distanceKm: () => null,
          etaMinutes: () => null,
        ),
      );
      return;
    }

    final distance = driverLocation.distanceToMeters(targetLoc);
    final distanceKm = distance / 1000;
    final minutes = (distance / 500).round();

    emit(
      state.copyWith(
        distanceKm: () => distanceKm,
        etaMinutes: () => minutes,
      ),
    );
  }

  /// Attempts to fetch the driving route between [start] and [end].
  /// Falls back to a straight line on error (OSRM timeout, etc.).
  ///
  /// If [routeGeometry] is provided (non-empty JSON string), it is parsed
  /// and used directly instead of calling OSRM. This avoids redundant OSRM
  /// calls for routes whose geometry was already calculated and stored.
  Future<void> fetchRoutePath({
    required Coordinates start,
    required Coordinates end,
    required RouteId routeId,
    String? routeGeometry,
  }) async {
    if (state.routePoints != null && state.loadedRouteId == routeId) return;
    if (state.isFetchingRoute) return;

    // Use stored geometry if available (avoids OSRM call)
    if (routeGeometry != null && routeGeometry.isNotEmpty) {
      final points = _parseGeometry(routeGeometry);
      if (points.isNotEmpty) {
        emit(
          state.copyWith(
            isFetchingRoute: false,
            routePoints: () => points,
            loadedRouteId: () => routeId,
            isApproximate: false,
          ),
        );
        return;
      }
    }

    emit(state.copyWith(isFetchingRoute: true));

    try {
      final result = await sl<RoutingService>().getRoute(start, end);
      if (isClosed) return;

      result.fold(
        (failure) {
          emit(
            state.copyWith(
              isFetchingRoute: false,
              routePoints: () => [
                LatLng(start.latitude, start.longitude),
                LatLng(end.latitude, end.longitude),
              ],
              loadedRouteId: () => routeId,
              isApproximate: true,
            ),
          );
        },
        (coords) {
          final points = coords
              .map((c) => LatLng(c.latitude, c.longitude))
              .toList();
          final isApprox = points.length == 2 &&
              points.first.latitude == start.latitude &&
              points.first.longitude == start.longitude &&
              points.last.latitude == end.latitude &&
              points.last.longitude == end.longitude;

          emit(
            state.copyWith(
              isFetchingRoute: false,
              routePoints: () => points,
              loadedRouteId: () => routeId,
              isApproximate: isApprox,
            ),
          );
        },
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isFetchingRoute: false,
          routePoints: () => [
            LatLng(start.latitude, start.longitude),
            LatLng(end.latitude, end.longitude),
          ],
          loadedRouteId: () => routeId,
          isApproximate: true,
        ),
      );
    }
  }

  /// Parses geometry JSON string to List<LatLng>.
  /// Expected format: [[lng, lat], [lng, lat], ...]
  List<LatLng> _parseGeometry(String geometryJson) {
    try {
      final decoded = json.decode(geometryJson);
      if (decoded is! List) return [];
      return decoded
          .whereType<List<Object?>>()
          .map((list) {
            if (list.length < 2) return null;
            final first = list[0];
            final second = list[1];
            if (first is! num || second is! num) return null;
            return LatLng(second.toDouble(), first.toDouble());
          })
          .whereType<LatLng>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Guards the rating sheet so it only opens once per trip.
  void markRatingShown() => emit(state.copyWith(ratingShown: true));

  /// Resets for a new trip.
  void reset() => emit(TrackingUiState.initial);
}
