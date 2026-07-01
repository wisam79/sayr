import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:sayr_mobile/core/map_config.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// OpenFreeMap-backed map widget with RTL support.
class SayrMap extends StatefulWidget {
  /// Creates a [SayrMap].
  const SayrMap({
    super.key,
    this.initialCameraPosition,
    this.onMapCreated,
    this.onMapLongClick,
    this.markers = const [],
    this.routePoints,
    this.myLocationEnabled = false,
    this.useCluster = false,
  });

  /// Whether to use marker clustering.
  final bool useCluster;

  /// The initial camera position.
  final CameraPosition? initialCameraPosition;

  /// Callback when the map controller is created.
  final void Function(MapLibreMapController)? onMapCreated;

  /// Callback when map is long clicked.
  final void Function(Point<double>, LatLng)? onMapLongClick;

  /// List of markers to place on the map.
  final List<SayrMarker> markers;

  /// List of route coordinates to draw a polyline on the map.
  final List<LatLng>? routePoints;

  /// Whether current user location is displayed.
  final bool myLocationEnabled;

  /// Default center: Baghdad.
  static const defaultCenter = LatLng(33.3152, 44.3661);

  @override
  State<SayrMap> createState() => _SayrMapState();
}

class _SayrMapState extends State<SayrMap> {
  MapLibreMapController? _controller;
  final Map<String, Symbol> _symbols = {};
  Line? _routeLine;
  bool _sourceAdded = false;
  late final Talker _logger;

  int _routeSyncRetryCount = 0;
  int _markerSyncRetryCount = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    _logger = sl<Talker>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_syncMarkers());
        unawaited(_syncRouteLine());
      }
    });
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(SayrMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      unawaited(_syncMarkers());
    }
    if (oldWidget.routePoints != widget.routePoints) {
      unawaited(_syncRouteLine());
    }
    if (oldWidget.initialCameraPosition?.target !=
        widget.initialCameraPosition?.target) {
      final target = widget.initialCameraPosition?.target;
      if (target != null && _controller != null) {
        unawaited(_controller!.animateCamera(CameraUpdate.newLatLng(target)));
      }
    }
  }

  Future<void> _syncRouteLine({bool isRetry = false}) async {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;

    if (!isRetry) {
      _routeSyncRetryCount = 0;
    }

    try {
      final oldLine = _routeLine;
      if (oldLine != null) {
        _routeLine = null;
        await controller.removeLine(oldLine);
      }

      final points = widget.routePoints;
      if (points != null && points.isNotEmpty) {
        if (!mounted) return;
        _routeLine = await controller.addLine(
          LineOptions(
            geometry: points,
            lineColor: '#3B82F6',
            lineWidth: 5,
            lineOpacity: 0.8,
          ),
        );
      }
    } catch (e, st) {
      if (_routeSyncRetryCount >= _maxRetries) {
        _logger.error(
          'Route line sync failed after $_maxRetries retries. Aborting.',
          e,
          st,
        );
        return;
      }
      _routeSyncRetryCount++;
      _logger.debug(
        'Route line sync failed (attempt $_routeSyncRetryCount/$_maxRetries); retrying in 1s',
        e,
        st,
      );
      if (!mounted) return;
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          unawaited(_syncRouteLine(isRetry: true));
        }
      });
    }
  }

  Future<void> _syncMarkers({bool isRetry = false}) async {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null) return;

    if (!isRetry) {
      _markerSyncRetryCount = 0;
    }

    if (widget.useCluster) {
      try {
        // Remove individual symbol markers if any exist
        final idsToRemove = _symbols.keys.toList();
        for (final id in idsToRemove) {
          final symbol = _symbols.remove(id);
          if (symbol != null) {
            if (!mounted) return;
            await controller.removeSymbol(symbol);
          }
        }

        final geojson = _buildGeoJson(widget.markers);

        if (!_sourceAdded) {
          if (!mounted) return;
          await controller.addSource(
            'markers-source',
            GeojsonSourceProperties(
              data: geojson,
              cluster: true,
              clusterMaxZoom: 14,
            ),
          );

          if (!mounted) return;
          // 1. Cluster circle layer
          await controller.addCircleLayer(
            'markers-source',
            'clusters-circle',
            const CircleLayerProperties(
              circleColor: [
                'step',
                ['get', 'point_count'],
                '#3B82F6',
                5,
                '#F59E0B',
                15,
                '#EF4444',
              ],
              circleRadius: [
                'step',
                ['get', 'point_count'],
                20.0,
                5,
                25.0,
                15,
                30.0,
              ],
            ),
            filter: ['has', 'point_count'],
          );

          if (!mounted) return;
          // 2. Cluster text labels layer
          await controller.addSymbolLayer(
            'markers-source',
            'clusters-label',
            const SymbolLayerProperties(
              textField: '{point_count}',
              textSize: 12.0,
              textColor: '#FFFFFF',
              textIgnorePlacement: true,
              textAllowOverlap: true,
            ),
            filter: ['has', 'point_count'],
          );

          if (!mounted) return;
          // 3. Unclustered points layer (actual buses)
          await controller.addSymbolLayer(
            'markers-source',
            'unclustered-points',
            const SymbolLayerProperties(
              iconImage: '{icon}',
              iconSize: 0.08,
              iconAllowOverlap: true,
            ),
            filter: [
              '!',
              ['has', 'point_count'],
            ],
          );

          _sourceAdded = true;
        } else {
          if (!mounted) return;
          await controller.setGeoJsonSource('markers-source', geojson);
        }
      } catch (e, st) {
        _sourceAdded = false;
        if (_markerSyncRetryCount >= _maxRetries) {
          _logger.error(
            'Marker sync (clustered) failed after $_maxRetries retries. Aborting.',
            e,
            st,
          );
          return;
        }
        _markerSyncRetryCount++;
        _logger.debug(
          'Marker sync (clustered) failed (attempt $_markerSyncRetryCount/$_maxRetries); retrying in 1s',
          e,
          st,
        );
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            unawaited(_syncMarkers(isRetry: true));
          }
        });
      }
    } else {
      try {
        final activeIds = <String>{};

        for (var i = 0; i < widget.markers.length; i++) {
          final marker = widget.markers[i];
          final id = marker.id ?? 'marker_$i';
          activeIds.add(id);

          final existingSymbol = _symbols[id];
          if (existingSymbol != null) {
            if (existingSymbol.options.geometry != marker.position ||
                existingSymbol.options.iconImage !=
                    (marker.iconImage ?? 'bus-icon') ||
                existingSymbol.options.iconSize != (marker.iconSize ?? 0.08)) {
              if (!mounted) return;
              await controller.updateSymbol(
                existingSymbol,
                SymbolOptions(
                  geometry: marker.position,
                  iconImage: marker.iconImage ?? 'bus-icon',
                  iconSize: marker.iconSize ?? 0.08,
                ),
              );
            }
          } else {
            if (!mounted) return;
            final symbol = await controller.addSymbol(
              SymbolOptions(
                geometry: marker.position,
                iconImage: marker.iconImage ?? 'bus-icon',
                iconSize: marker.iconSize ?? 0.08,
              ),
            );
            _symbols[id] = symbol;
          }
        }

        final idsToRemove =
            _symbols.keys.where((id) => !activeIds.contains(id)).toList();
        for (final id in idsToRemove) {
          final symbol = _symbols.remove(id);
          if (symbol != null) {
            if (!mounted) return;
            await controller.removeSymbol(symbol);
          }
        }
      } catch (e, st) {
        if (_markerSyncRetryCount >= _maxRetries) {
          _logger.error(
            'Marker sync (non-clustered) failed after $_maxRetries retries. Aborting.',
            e,
            st,
          );
          return;
        }
        _markerSyncRetryCount++;
        _logger.debug(
          'Marker sync (non-clustered) failed (attempt $_markerSyncRetryCount/$_maxRetries); retrying in 1s',
          e,
          st,
        );
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            unawaited(_syncMarkers(isRetry: true));
          }
        });
      }
    }
  }

  Map<String, Object?> _buildGeoJson(List<SayrMarker> markers) {
    return {
      'type': 'FeatureCollection',
      'features': markers.map((marker) {
        return {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [
              marker.position.longitude,
              marker.position.latitude,
            ],
          },
          'properties': {
            'id': marker.id,
            'icon': marker.iconImage ?? 'bus-icon',
          },
        };
      }).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Container(
        key: const Key('sayr_map_placeholder'),
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            'Map Placeholder',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapStyle = isDark ? openFreeMapDarkStyle : openFreeMapLightStyle;

    return Semantics(
        label: 'Trip Map', // This map represents the active trip or routes
        child: MapLibreMap(
          initialCameraPosition: widget.initialCameraPosition ??
              const CameraPosition(
                target: SayrMap.defaultCenter,
                zoom: 13,
              ),
          styleString: mapStyle,
          myLocationEnabled: widget.myLocationEnabled,
          onMapCreated: (controller) {
            _controller = controller;
            widget.onMapCreated?.call(controller);
            unawaited(_syncMarkers());
            unawaited(_syncRouteLine());
          },
          onMapLongClick: widget.onMapLongClick,
        ),
      );
  }
}

/// A simple marker to display on the map.
class SayrMarker {
  /// Creates a [SayrMarker].
  const SayrMarker({
    required this.position,
    this.id,
    this.iconImage,
    this.iconSize,
    this.data,
  });

  /// Coordinates of the marker.
  final LatLng position;

  /// Optional unique identifier.
  final String? id;

  /// Optional icon asset name.
  final String? iconImage;

  /// Scale of the icon on map.
  final double? iconSize;

  /// User data payload.
  final Object? data;
}
