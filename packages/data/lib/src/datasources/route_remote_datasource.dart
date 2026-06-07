import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Bus route CRUD + search + driver route list.
abstract class RouteRemoteDatasource {
  /// Returns all active routes.
  Future<List<Map<String, dynamic>>> getActiveRoutes();

  /// Returns the active routes owned by the current driver.
  Future<List<Map<String, dynamic>>> getMyDriverRoutes();

  /// Fetches a single route by id.
  Future<Map<String, dynamic>?> getRouteById(String id);

  /// Searches active routes by title/start/end location substring.
  Future<List<Map<String, dynamic>>> searchRoutes(String query);
}

@LazySingleton(as: RouteRemoteDatasource)
class RouteRemoteDatasourceImpl implements RouteRemoteDatasource {
  RouteRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;
  supabase.User? get _currentUser => _supabase.currentUser;

  @override
  Future<List<Map<String, dynamic>>> getActiveRoutes() async {
    final response = await _client
        .from('routes')
        .select()
        .eq('is_active', true)
        .order('title');
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getMyDriverRoutes() async {
    final userId = _currentUser?.id;
    if (userId == null) {
      throw const supabase.AuthException('Not authenticated');
    }

    final driver = await _client
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    final driverId = driver?['id'] as String?;
    if (driverId == null) {
      return <Map<String, dynamic>>[];
    }

    final response = await _client
        .from('routes')
        .select()
        .eq('driver_id', driverId)
        .eq('is_active', true)
        .order('title');
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> getRouteById(String id) =>
      _client.from('routes').select().eq('id', id).maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> searchRoutes(String query) async {
    final response = await _client
        .from('routes')
        .select()
        .eq('is_active', true)
        .or(
          'title.ilike.%$query%,start_location.ilike.%$query%,end_location.ilike.%$query%',
        )
        .order('title');
    return (response as List).cast<Map<String, dynamic>>();
  }
}
