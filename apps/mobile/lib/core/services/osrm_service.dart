import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:retry/retry.dart';

/// Service to query project-osrm.org public routing API.
@lazySingleton
class OsrmService {
  /// Creates an [OsrmService].
  OsrmService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
    _dio.interceptors.add(
      LogInterceptor(
        responseHeader: false,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  Dio _dio;
  final Logger _logger = Logger();

  /// Getter/Setter for mock injections in testing.
  @visibleForTesting
  Dio get dioInstance => _dio;

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

      final response = await retry(
        () => _dio.get<Map<String, dynamic>>(url),
        retryIf: (e) => e is DioException && e.type != DioExceptionType.cancel,
        maxAttempts: 3,
        delayFactor: const Duration(milliseconds: 10),
      );

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
