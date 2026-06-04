import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/route_model.dart';
import '../supabase/supabase_client.dart';

/// Repository for route operations.
@lazySingleton
class RouteRepository {
  RouteRepository({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;

  /// Fetch all active routes.
  Future<Either<Failure, List<Route>>> getActiveRoutes() async {
    try {
      final response = await _supabase.client
          .from('routes')
          .select()
          .eq('is_active', true)
          .order('title');

      final routes = (response as List<dynamic>)
          .map((json) => RouteModel.fromJson(json as Map<String, dynamic>))
          .map((model) => model.toEntity())
          .toList();

      return Right(routes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetch a route by ID.
  Future<Either<Failure, Route>> getById(RouteId id) async {
    try {
      final response = await _supabase.client
          .from('routes')
          .select()
          .eq('id', id.value)
          .maybeSingle();

      if (response == null) {
        return Left(NotFoundFailure(resource: 'route'));
      }

      final route = RouteModel.fromJson(response).toEntity();
      return Right(route);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Search routes by query.
  Future<Either<Failure, List<Route>>> search(String query) async {
    try {
      final response = await _supabase.client
          .from('routes')
          .select()
          .eq('is_active', true)
          .or('title.ilike.%$query%,start_location.ilike.%$query%,end_location.ilike.%$query%')
          .order('title');

      final routes = (response as List<dynamic>)
          .map((json) => RouteModel.fromJson(json as Map<String, dynamic>))
          .map((model) => model.toEntity())
          .toList();

      return Right(routes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
