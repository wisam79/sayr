import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:sayr_mobile/core/map_config.dart';

/// OpenFreeMap-backed map widget with RTL support.
class SayrMap extends StatefulWidget {
  /// Creates a [SayrMap].
  const SayrMap({
    super.key,
    this.initialCameraPosition,
    this.onMapCreated,
    this.onMapLongClick,
    this.markers = const [],
    this.myLocationEnabled = false,
  });

  /// The initial camera position.
  final CameraPosition? initialCameraPosition;

  /// Callback when the map controller is created.
  final void Function(MapLibreMapController)? onMapCreated;

  /// Callback when map is long clicked.
  final void Function(Point<double>, LatLng)? onMapLongClick;

  /// List of markers to place on the map.
  final List<SayrMarker> markers;

  /// Whether current user location is displayed.
  final bool myLocationEnabled;

  /// Default center: Baghdad.
  static const defaultCenter = LatLng(33.3152, 44.3661);

  @override
  State<SayrMap> createState() => _SayrMapState();
}

class _SayrMapState extends State<SayrMap> {
  MapLibreMapController? _controller;

  @override
  void initState() {
    super.initState();
    // Sync markers when controller is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncMarkers());
    });
  }

  @override
  void didUpdateWidget(SayrMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      unawaited(_syncMarkers());
    }
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      await controller.clearSymbols();
      for (final marker in widget.markers) {
        await controller.addSymbol(
          SymbolOptions(
            geometry: marker.position,
            iconImage: marker.iconImage ?? 'bus-icon',
            iconSize: marker.iconSize ?? 0.08,
          ),
        );
      }
    } catch (e) {
      // The symbol manager or channel may not be initialized yet.
      // Retry in the next frame to prevent runtime crashes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_syncMarkers());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      initialCameraPosition: widget.initialCameraPosition ??
          const CameraPosition(
            target: SayrMap.defaultCenter,
            zoom: 13,
          ),
      styleString: openFreeMapStyleUrl,
      myLocationEnabled: widget.myLocationEnabled,
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
        unawaited(_syncMarkers());
      },
      onMapLongClick: widget.onMapLongClick,
    );
  }
}

/// A simple marker to display on the map.
class SayrMarker {
  /// Creates a [SayrMarker].
  const SayrMarker({
    required this.position,
    this.iconImage,
    this.iconSize,
    this.data,
  });

  /// Coordinates of the marker.
  final LatLng position;

  /// Optional icon asset name.
  final String? iconImage;

  /// Scale of the icon on map.
  final double? iconSize;

  /// User data payload.
  final Object? data;
}
