import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:flutter/foundation.dart';

/// Service to query project-osrm.org public routing API.
@lazySingleton
class OsrmService {
  /// Creates an [OsrmService].
  OsrmService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }

  Dio _dio;
  final Logger _logger = Logger();

  /// Setter for mock injections in testing.
  @visibleForTesting
  set dioInstance(Dio value) => _dio = value;

  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  /// Queries the OSRM driving route API and returns the geometry as a list of [LatLng].
  ///
  /// Falls back to a straight line [start, end] on failure or timeout.
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url =
          '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await _dio.get<Map<String, dynamic>>(url);

      if (response.statusCode == 200 && response.data != null) {
        final routes = response.data!['routes'] as List<dynamic>;
        if (routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          return coordinates.map((coord) {
            final point = coord as List<dynamic>;
            return LatLng(
              (point[1] as num).toDouble(),
              (point[0] as num).toDouble(),
            );
          }).toList();
        }
      }
    } catch (e, st) {
      _logger.w(
        'OSRM route request failed; falling back to straight line',
        error: e,
        stackTrace: st,
      );
    }
    return [start, end];
  }
}
