import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Concrete implementation of [RatingRepository] using the remote datasource.
@LazySingleton(as: RatingRepository)
class RatingRepositoryImpl extends BaseRepository implements RatingRepository {
  RatingRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required super.talker,
  }) : _remoteDatasource = remoteDatasource;

  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, Rating>> submitRating({
    required TripId tripId,
    required DriverId driverId,
    required int rating,
    String? comment,
  }) async {
    return guard(() async {
      final studentId = _remoteDatasource.currentUser?.id;
      if (studentId == null) {
        throw const UnauthorizedFailure();
      }
      final response = await _remoteDatasource.submitRating(
        tripId: tripId.value,
        driverId: driverId.value,
        studentId: studentId,
        rating: rating,
        comment: comment,
      );
      return response.toEntity();
    });
  }

  @override
  Future<Either<Failure, Rating?>> getTripRating(TripId tripId) async {
    return guard(() async {
      final studentId = _remoteDatasource.currentUser?.id;
      if (studentId == null) {
        throw const UnauthorizedFailure();
      }
      final response = await _remoteDatasource.getTripRating(
        tripId: tripId.value,
        studentId: studentId,
      );
      if (response == null) {
        return null;
      }
      return response.toEntity();
    });
  }
}
