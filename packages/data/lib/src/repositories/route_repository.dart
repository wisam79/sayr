import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/route_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Concrete implementation of RouteRepository using Remote and Local data sources.
@LazySingleton(as: RouteRepository)
class RouteRepositoryImpl extends BaseRepository implements RouteRepository {
  RouteRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
    required super.talker,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;
  final RemoteDatasource _remoteDatasource;
  final LocalDatasource _localDatasource;

  @override
  Future<Either<Failure, List<Route>>> getActiveRoutes() async {
    try {
      final response = await _remoteDatasource.getActiveRoutes();
      final routes =
          response.map((json) => RouteModel.fromJson(json).toEntity()).toList();
      try {
        await _localDatasource.cacheRoutes(routes);
      } catch (e, st) {
        log.warning(
          'Failed to cache active routes; serving from network only',
          e,
          st,
        );
      }
      return Right(routes);
    } catch (e) {
      try {
        final cached = await _localDatasource.getCachedRoutes();
        if (cached.isNotEmpty) {
          return Right(cached);
        }
      } catch (cacheError, st) {
        log.warning(
          'Failed to read cached routes during offline fallback',
          cacheError,
          st,
        );
      }
      return Left(mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<Route>>> getMyDriverRoutes() async {
    try {
      final response = await _remoteDatasource.getMyDriverRoutes();
      final routes =
          response.map((json) => RouteModel.fromJson(json).toEntity()).toList();
      try {
        await _localDatasource.cacheRoutes(routes);
      } catch (e, st) {
        log.warning(
          'Failed to cache driver routes; serving from network only',
          e,
          st,
        );
      }
      return Right(routes);
    } catch (e) {
      try {
        final cached = await _localDatasource.getCachedRoutes();
        if (cached.isNotEmpty) {
          return Right(cached);
        }
      } catch (cacheError, st) {
        log.warning(
          'Failed to read cached driver routes during offline fallback',
          cacheError,
          st,
        );
      }
      return Left(mapException(e));
    }
  }

  @override
  Future<Either<Failure, Route>> getById(RouteId id) async {
    try {
      final response = await _remoteDatasource.getRouteById(id.value);
      if (response == null) {
        return const Left(NotFoundFailure(resource: 'route'));
      }
      final route = RouteModel.fromJson(response).toEntity();
      return Right(route);
    } catch (e) {
      try {
        final cached = await _localDatasource.getCachedRoutes();
        final route = cached.firstWhere((r) => r.id == id);
        return Right(route);
      } catch (cacheError, st) {
        log.warning(
          'Failed to read cached route during offline fallback',
          cacheError,
          st,
        );
      }
      return Left(mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<Route>>> search(String query) async {
    return guard(() async {
      final response = await _remoteDatasource.searchRoutes(query);
      return response
          .map((json) => RouteModel.fromJson(json).toEntity())
          .toList();
    });
  }
}
