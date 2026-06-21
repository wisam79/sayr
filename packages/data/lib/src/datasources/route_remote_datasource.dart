import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/models/route_model.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Bus route CRUD + search + driver route list.
abstract class RouteRemoteDatasource {
  /// Returns all active routes.
  Future<List<RouteModel>> getActiveRoutes();

  /// Returns the active routes owned by the current driver.
  Future<List<RouteModel>> getMyDriverRoutes();

  /// Fetches a single route by id.
  Future<RouteModel?> getRouteById(String id);

  /// Searches active routes by title/start/end location substring.
  Future<List<RouteModel>> searchRoutes(String query);
}

@LazySingleton(as: RouteRemoteDatasource)
class RouteRemoteDatasourceImpl implements RouteRemoteDatasource {
  RouteRemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;
  final SayrSupabase _supabase;

  supabase.SupabaseClient get _client => _supabase.client;
  supabase.User? get _currentUser => _supabase.currentUser;

  @override
  Future<List<RouteModel>> getActiveRoutes() async {
    return await _client
        .from('routes')
        .select()
        .eq('is_active', true)
        .order('title')
        .withConverter((data) => data.map((e) => RouteModel.fromJson(e)).toList());
  }

  @override
  Future<List<RouteModel>> getMyDriverRoutes() async {
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
      return <RouteModel>[];
    }

    return await _client
        .from('routes')
        .select()
        .eq('driver_id', driverId)
        .eq('is_active', true)
        .order('title')
        .withConverter((data) => data.map((e) => RouteModel.fromJson(e)).toList());
  }

  @override
  Future<RouteModel?> getRouteById(String id) async {
    final data = await _client.from('routes').select().eq('id', id).maybeSingle();
    return data != null ? RouteModel.fromJson(data) : null;
  }

  @override
  Future<List<RouteModel>> searchRoutes(String query) async {
    return await _client
        .from('routes')
        .select()
        .eq('is_active', true)
        .or(
          'title.ilike.%$query%,start_location.ilike.%$query%,end_location.ilike.%$query%',
        )
        .order('title')
        .withConverter((data) => data.map((e) => RouteModel.fromJson(e)).toList());
  }
}
