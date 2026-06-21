import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/boarding_record_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Concrete implementation of [BoardingRepository] using the remote datasource.
@LazySingleton(as: BoardingRepository)
class BoardingRepositoryImpl extends BaseRepository
    implements BoardingRepository {
  /// Creates a [BoardingRepositoryImpl].
  BoardingRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required super.talker,
  }) : _remoteDatasource = remoteDatasource;
  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, TripId?>> getActiveTripForSubscription() async {
    return guard(() async {
      final id = await _remoteDatasource.getActiveTripForSubscription();
      return id == null ? null : TripId(id);
    });
  }

  @override
  Future<Either<Failure, BoardingTokenResult>> generateBoardingToken(
    TripId tripId,
  ) async {
    return guard(() async {
      final result =
          await _remoteDatasource.generateBoardingToken(tripId.value);
      return BoardingTokenResult(
        token: result.token,
        expiresAt: result.expiresAt,
      );
    });
  }

  @override
  Future<Either<Failure, BoardingRecord>> validateBoarding({
    required String token,
    required TripId tripId,
    Coordinates? driverLocation,
  }) async {
    return guard(() async {
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
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<BoardingRecord>>> getTripPassengers(
    TripId tripId,
  ) async {
    return guard(() async {
      final rows = await _remoteDatasource.getTripPassengers(tripId.value);
      return rows
          .map(
            (r) => BoardingRecordModel(
              id: r['boarding_id'] as String,
              tripId: tripId.value,
              subscriptionId:
                  null, // not returned by RPC; sufficient for list view
              studentId: r['student_id'] as String,
              studentName: r['student_name'] as String?,
              boardedAt: DateTime.parse(r['boarded_at'] as String),
              boardingMethod: r['boarding_method'] as String? ?? 'qr_scan',
            ),
          )
          .map((m) => m.toEntity())
          .toList();
    });
  }

  @override
  Stream<List<BoardingRecord>> watchTripPassengers(TripId tripId) {
    return _remoteDatasource.watchTripPassengers(tripId.value).asyncMap(
      (rows) async {
        if (rows.isEmpty) return const <BoardingRecord>[];

        final studentIds =
            rows.map((r) => r['student_id'] as String).toSet().toList();

        try {
          final profiles =
              await _remoteDatasource.getPublicProfiles(studentIds);
          final nameMap = {
            for (final p in profiles) p.id: p.fullName,
          };

          return rows.map((r) {
            final studentId = r['student_id'] as String;
            return BoardingRecordModel(
              id: r['id'] as String,
              tripId: tripId.value,
              subscriptionId: r['subscription_id'] as String? ?? '',
              studentId: studentId,
              studentName: nameMap[studentId],
              boardedAt: DateTime.parse(r['boarded_at'] as String),
              boardingMethod: r['boarding_method'] as String? ?? 'qr_scan',
            ).toEntity();
          }).toList();
        } catch (e, st) {
          log.warning(
              'Failed to resolve student names in watchTripPassengers', e, st);
          return rows.map((r) {
            final studentId = r['student_id'] as String;
            return BoardingRecordModel(
              id: r['id'] as String,
              tripId: tripId.value,
              subscriptionId: r['subscription_id'] as String? ?? '',
              studentId: studentId,
              studentName: null,
              boardedAt: DateTime.parse(r['boarded_at'] as String),
              boardingMethod: r['boarding_method'] as String? ?? 'qr_scan',
            ).toEntity();
          }).toList();
        }
      },
    );
  }

  @override
  Future<Either<Failure, BoardingRecord>> validateBoardingViaProximity({
    required TripId tripId,
    required String otp,
    Coordinates? studentLocation,
  }) async {
    return guard(() async {
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
      return model.toEntity();
    });
  }
}
