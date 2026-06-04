import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/map_config.dart';

/// OpenFreeMap-backed map widget with RTL support.
class SayrMap extends StatefulWidget {
  const SayrMap({
    super.key,
    this.initialCameraPosition,
    this.onMapCreated,
    this.onMapLongClick,
    this.markers = const [],
    this.myLocationEnabled = false,
  });

  final CameraPosition? initialCameraPosition;
  final void Function(MapLibreMapController)? onMapCreated;
  final void Function(Point<double>, LatLng)? onMapLongClick;
  final List<SayrMarker> markers;
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
      _syncMarkers();
    });
  }

  @override
  void didUpdateWidget(SayrMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      _syncMarkers();
    }
  }

  void _syncMarkers() {
    final controller = _controller;
    if (controller == null) return;

    controller.clearSymbols();
    for (final marker in widget.markers) {
      controller.addSymbol(
        SymbolOptions(
          geometry: marker.position,
          iconImage: marker.iconImage ?? 'bus-icon',
          iconSize: marker.iconSize ?? 0.08,
        ),
      );
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
        _syncMarkers();
      },
      onMapLongClick: widget.onMapLongClick,
    );
  }
}

/// A simple marker to display on the map.
class SayrMarker {
  const SayrMarker({
    required this.position,
    this.iconImage,
    this.iconSize,
    this.data,
  });

  final LatLng position;
  final String? iconImage;
  final double? iconSize;
  final Object? data;
}
