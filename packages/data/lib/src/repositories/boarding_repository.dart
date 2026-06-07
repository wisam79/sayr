import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/boarding_record_model.dart';

/// Concrete implementation of [BoardingRepository] using the remote datasource.
@LazySingleton(as: BoardingRepository)
class BoardingRepositoryImpl implements BoardingRepository {
  /// Creates a [BoardingRepositoryImpl].
  BoardingRepositoryImpl({required RemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;
  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, TripId?>> getActiveTripForSubscription() async {
    try {
      final id = await _remoteDatasource.getActiveTripForSubscription();
      return Right<Failure, TripId?>(id == null ? null : TripId(id));
    } catch (e) {
      return Left<Failure, TripId?>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BoardingTokenResult>> generateBoardingToken(
    TripId tripId,
  ) async {
    try {
      final result =
          await _remoteDatasource.generateBoardingToken(tripId.value);
      return Right<Failure, BoardingTokenResult>(
        BoardingTokenResult(token: result.token, expiresAt: result.expiresAt),
      );
    } catch (e) {
      return Left<Failure, BoardingTokenResult>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, BoardingRecord>> validateBoarding({
    required String token,
    required TripId tripId,
    Coordinates? driverLocation,
  }) async {
    try {
      final row = await _remoteDatasource.validateBoarding(
        token: token,
        tripId: tripId.value,
        lat: driverLocation?.latitude,
        lng: driverLocation?.longitude,
      );
      // The RPC returns the fields directly (joined with student name).
      final model = BoardingRecordModel(
        id: row['boarding_id'] as String,
        tripId: tripId.value,
        subscriptionId: row['subscription_id'] as String,
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String?,
        boardedAt: DateTime.parse(row['boarded_at'] as String),
        boardingMethod: 'qr_scan',
      );
      return Right<Failure, BoardingRecord>(model.toEntity());
    } catch (e) {
      return Left<Failure, BoardingRecord>(
          ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BoardingRecord>>> getTripPassengers(
    TripId tripId,
  ) async {
    try {
      final rows = await _remoteDatasource.getTripPassengers(tripId.value);
      final records = rows
          .map(
            (r) => BoardingRecordModel(
              id: r['boarding_id'] as String,
              tripId: tripId.value,
              subscriptionId:
                  '', // not returned by RPC; sufficient for list view
              studentId: r['student_id'] as String,
              studentName: r['student_name'] as String?,
              boardedAt: DateTime.parse(r['boarded_at'] as String),
              boardingMethod: r['boarding_method'] as String? ?? 'qr_scan',
            ),
          )
          .map((m) => m.toEntity())
          .toList();
      return Right<Failure, List<BoardingRecord>>(records);
    } catch (e) {
      return Left<Failure, List<BoardingRecord>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Stream<List<BoardingRecord>> watchTripPassengers(TripId tripId) {
    return _remoteDatasource.watchTripPassengers(tripId.value).map(
          (rows) => rows
              .map(
                (r) => BoardingRecordModel(
                  id: r['id'] as String,
                  tripId: tripId.value,
                  subscriptionId: r['subscription_id'] as String? ?? '',
                  studentId: r['student_id'] as String,
                  studentName: null,
                  boardedAt: DateTime.parse(r['boarded_at'] as String),
                  boardingMethod: r['boarding_method'] as String? ?? 'qr_scan',
                ).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Future<Either<Failure, BoardingRecord>> validateBoardingViaProximity({
    required TripId tripId,
    required String otp,
    Coordinates? studentLocation,
  }) async {
    try {
      final row = await _remoteDatasource.validateBoardingViaProximity(
        tripId: tripId.value,
        otp: otp,
        lat: studentLocation?.latitude,
        lng: studentLocation?.longitude,
      );
      final model = BoardingRecordModel(
        id: row['boarding_id'] as String,
        tripId: tripId.value,
        subscriptionId: row['subscription_id'] as String,
        studentId: row['student_id'] as String,
        studentName: row['student_name'] as String?,
        boardedAt: DateTime.parse(row['boarded_at'] as String),
        boardingMethod: 'self_check_in',
      );
      return Right<Failure, BoardingRecord>(model.toEntity());
    } catch (e) {
      return Left<Failure, BoardingRecord>(
          ServerFailure(message: e.toString()));
    }
  }
}
