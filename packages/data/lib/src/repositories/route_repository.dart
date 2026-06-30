import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
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

  /// Runs [fetch] against the remote source, caches the result on success, and
  /// transparently falls back to the local cache when the network call fails.
  ///
  /// This wraps the offline-fallback behaviour that route reads need (a route
  /// list may have been cached during a previous session) while still routing
  /// every failure through the shared [mapException] mapper so callers receive
  /// a typed [Failure].
  Future<Either<Failure, ({List<Route> routes, bool fromCache})>>
      _fetchWithCacheFallback(
    Future<List<Route>> Function() fetch, {
    required String cacheLogLabel,
  }) async {
    final result = await guard(() async {
      final routes = await fetch();
      try {
        await _localDatasource.cacheRoutes(routes);
      } catch (e, st) {
        log.warning(
          'Failed to cache $cacheLogLabel; serving from network only',
          e,
          st,
        );
      }
      return routes;
    });

    return result.fold(
      (failure) async {
        try {
          final cached = await _localDatasource.getCachedRoutes();
          if (cached.isNotEmpty) {
            return Right((routes: cached, fromCache: true));
          }
        } catch (cacheError, st) {
          log.warning(
            'Failed to read cached $cacheLogLabel during offline fallback',
            cacheError,
            st,
          );
        }
        return Left(failure);
      },
      (routes) async => Right((routes: routes, fromCache: false)),
    );
  }

  @override
  Future<Either<Failure, ({List<Route> routes, bool fromCache})>>
      getActiveRoutes() async {
    return _fetchWithCacheFallback(
      () async {
        final response = await _remoteDatasource.getActiveRoutes();
        return response.map((model) => model.toEntity()).toList();
      },
      cacheLogLabel: 'active routes',
    );
  }

  @override
  Future<Either<Failure, List<Route>>> getMyDriverRoutes() async {
    final result = await _fetchWithCacheFallback(
      () async {
        final response = await _remoteDatasource.getMyDriverRoutes();
        return response.map((model) => model.toEntity()).toList();
      },
      cacheLogLabel: 'driver routes',
    );
    return result.map((data) => data.routes);
  }

  @override
  Future<Either<Failure, Route>> getById(RouteId id) async {
    return guard(() async {
      try {
        final response = await _remoteDatasource.getRouteById(id.value);
        if (response == null) {
          throw const NotFoundFailure(resource: 'route');
        }
        return response.toEntity();
      } on Failure {
        rethrow;
      } catch (e) {
        // Offline fallback: look the route up in the local cache by id.
        try {
          final cached = await _localDatasource.getCachedRoutes();
          final route = cached.firstWhere(
            (r) => r.id == id,
            orElse: () => throw const NotFoundFailure(resource: 'route'),
          );
          return route;
        } catch (cacheError, st) {
          log.warning(
            'Failed to read cached route during offline fallback',
            cacheError,
            st,
          );
        }
        rethrow;
      }
    });
  }

  @override
  Future<Either<Failure, List<Route>>> search(String query) async {
    return guard(() async {
      final response = await _remoteDatasource.searchRoutes(query);
      return response.map((model) => model.toEntity()).toList();
    });
  }
}
