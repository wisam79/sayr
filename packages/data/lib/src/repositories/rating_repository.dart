import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';

/// Concrete implementation of [RatingRepository] using the remote datasource.
@LazySingleton(as: RatingRepository)
class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl({required RemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, Rating>> submitRating({
    required TripId tripId,
    required DriverId driverId,
    required int rating,
    String? comment,
  }) async {
    try {
      final studentId = _remoteDatasource.currentUser?.id;
      if (studentId == null) {
        return const Left<Failure, Rating>(UnauthorizedFailure());
      }
      final response = await _remoteDatasource.submitRating(
        tripId: tripId.value,
        driverId: driverId.value,
        studentId: studentId,
        rating: rating,
        comment: comment,
      );
      return Right<Failure, Rating>(_ratingFromDb(response));
    } catch (e) {
      return Left<Failure, Rating>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Rating?>> getTripRating(TripId tripId) async {
    try {
      final studentId = _remoteDatasource.currentUser?.id;
      if (studentId == null) {
        return const Left<Failure, Rating?>(UnauthorizedFailure());
      }
      final response = await _remoteDatasource.getTripRating(
        tripId: tripId.value,
        studentId: studentId,
      );
      if (response == null) {
        return const Right<Failure, Rating?>(null);
      }
      return Right<Failure, Rating?>(_ratingFromDb(response));
    } catch (e) {
      return Left<Failure, Rating?>(ServerFailure(message: e.toString()));
    }
  }

  Rating _ratingFromDb(Map<String, dynamic> json) {
    return Rating(
      id: RatingId(json['id'] as String),
      tripId: TripId(json['trip_id'] as String),
      studentId: UserId(json['student_id'] as String),
      driverId: DriverId(json['driver_id'] as String),
      rating: (json['rating'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      comment: json['comment'] as String?,
    );
  }
}
