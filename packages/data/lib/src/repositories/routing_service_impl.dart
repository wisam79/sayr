import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/osrm_remote_datasource.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

@LazySingleton(as: RoutingService)
class RoutingServiceImpl extends BaseRepository implements RoutingService {
  /// Creates a [RoutingServiceImpl] with the given [datasource] and [talker] instances.
  RoutingServiceImpl({
    required OsrmRemoteDatasource datasource,
    required super.talker,
  }) : _datasource = datasource;

  final OsrmRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<Coordinates>>> getRoute(
    Coordinates start,
    Coordinates end,
  ) {
    return guard(() => _datasource.getRouteGeometry(start, end));
  }
}
