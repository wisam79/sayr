import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:retry/retry.dart';
import 'package:sayr_data/sayr_data.dart';

/// Service to fetch route geometry via Supabase Edge Function proxy.
///
/// The Edge Function (`get-route-geometry`) calls OSRM hosted on Hugging Face
/// with the HF_TOKEN — the client never knows the HF Space URL or token.
@lazySingleton
class OsrmService {
  OsrmService({SayrSupabase? supabase}) : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;
  final Logger _logger = Logger();

  /// Queries route geometry via the Supabase Edge Function proxy.
  ///
  /// Falls back to a straight line [start, end] on failure or timeout.
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final response = await retry(
        () => _supabase.client.functions.invoke(
          'get-route-geometry',
          body: {
            'startLng': start.longitude,
            'startLat': start.latitude,
            'endLng': end.longitude,
            'endLat': end.latitude,
          },
        ),
        maxAttempts: 2,
        retryIf: (_) => true,
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) return [start, end];

      final coordinates = data['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) return [start, end];

      return coordinates.map((coord) {
        if (coord is! List<dynamic> || coord.length < 2) return null;
        final lat = coord[1];
        final lng = coord[0];
        if (lat is! num || lng is! num) return null;
        return LatLng(lat.toDouble(), lng.toDouble());
      }).whereType<LatLng>().toList();
    } catch (e, st) {
      _logger.w(
        'Route geometry fetch failed; falling back to straight line',
        error: e,
        stackTrace: st,
      );
    }
    return [start, end];
  }
}
