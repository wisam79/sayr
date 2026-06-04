import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../datasources/remote_datasource.dart';
import '../datasources/local_datasource.dart';
import '../models/route_model.dart';

/// Concrete implementation of RouteRepository using Remote and Local data sources.
@LazySingleton(as: RouteRepository)
class RouteRepositoryImpl implements RouteRepository {
  final RemoteDatasource _remoteDatasource;
  final LocalDatasource _localDatasource;

  RouteRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  @override
  Future<Either<Failure, List<Route>>> getActiveRoutes() async {
    try {
      final response = await _remoteDatasource.getActiveRoutes();
      final routes =
          response.map((json) => RouteModel.fromJson(json).toEntity()).toList();
      return Right(routes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Route>>> getMyDriverRoutes() async {
    try {
      final response = await _remoteDatasource.getMyDriverRoutes();
      final routes =
          response.map((json) => RouteModel.fromJson(json).toEntity()).toList();
      return Right(routes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Route>> getById(RouteId id) async {
    try {
      final response = await _remoteDatasource.getRouteById(id.value);
      if (response == null) {
        return Left(NotFoundFailure(resource: 'route'));
      }
      final route = RouteModel.fromJson(response).toEntity();
      return Right(route);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Route>>> search(String query) async {
    try {
      final response = await _remoteDatasource.searchRoutes(query);
      final routes =
          response.map((json) => RouteModel.fromJson(json).toEntity()).toList();
      return Right(routes);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
