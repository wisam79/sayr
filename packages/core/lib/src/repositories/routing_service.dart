import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/src/failures/failure.dart';
import 'package:sayr_core/src/value_objects/coordinates.dart';

/// Abstract interface for fetching route geometries.
// ignore: one_member_abstracts
abstract class RoutingService {
  /// Fetches route coordinates between a start and end point.
  Future<Either<Failure, List<Coordinates>>> getRoute(
    Coordinates start,
    Coordinates end,
  );
}
