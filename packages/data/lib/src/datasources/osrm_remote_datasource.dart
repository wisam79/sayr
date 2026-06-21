import 'package:injectable/injectable.dart';
import 'package:retry/retry.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';

@lazySingleton
class OsrmRemoteDatasource {
  /// Creates an [OsrmRemoteDatasource] with the given [supabase] instance.
  OsrmRemoteDatasource({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// Queries route geometry via the Supabase Edge Function proxy.
  /// Throws [Exception] on network or format errors.
  Future<List<Coordinates>> getRouteGeometry(
    Coordinates start,
    Coordinates end,
  ) async {
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

    if (response.status != 200) {
      throw Exception(
          'Failed to fetch route geometry: HTTP ${response.status}');
    }

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Empty response from routing service');
    }

    final coordinates = data['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.isEmpty) {
      throw Exception('No coordinates returned from routing service');
    }

    return coordinates
        .map((coord) {
          if (coord is! List<dynamic> || coord.length < 2) return null;
          final lat = coord[1];
          final lng = coord[0];
          if (lat is! num || lng is! num) return null;
          return Coordinates(
            latitude: lat.toDouble(),
            longitude: lng.toDouble(),
          );
        })
        .whereType<Coordinates>()
        .toList();
  }
}
