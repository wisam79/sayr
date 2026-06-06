import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/emergency_report_model.dart';

/// Concrete implementation of EmergencyRepository using Remote data source.
@LazySingleton(as: EmergencyRepository)
class EmergencyRepositoryImpl implements EmergencyRepository {
  EmergencyRepositoryImpl({
    required RemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;
  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, EmergencyReport>> triggerEmergency({
    required TripId tripId,
    required RouteId routeId,
    required Coordinates location,
    String? message,
  }) async {
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, EmergencyReport>(UnauthorizedFailure());
      }

      final reportId = await _remoteDatasource.triggerEmergency(
        tripId: tripId.value,
        routeId: routeId.value,
        studentId: currentUserId,
        lat: location.latitude,
        lng: location.longitude,
        description: message ?? '',
      );

      final model = EmergencyReportModel(
        id: reportId,
        userId: currentUserId,
        tripId: tripId.value,
        latitude: location.latitude,
        longitude: location.longitude,
        createdAt: DateTime.now().toUtc(),
      );

      return Right<Failure, EmergencyReport>(model.toEntity());
    } catch (e) {
      return Left<Failure, EmergencyReport>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, EmergencyReport?>> getActiveReport() async {
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, EmergencyReport?>(UnauthorizedFailure());
      }

      final response =
          await _remoteDatasource.getActiveEmergencyReport(currentUserId);
      if (response == null) {
        return const Right<Failure, EmergencyReport?>(null);
      }

      // Map latitude and longitude properly for DTO
      final map = {
        ...response,
        'latitude': (response['latitude'] as num).toDouble(),
        'longitude': (response['longitude'] as num).toDouble(),
      };

      return Right<Failure, EmergencyReport?>(
        EmergencyReportModel.fromJson(map).toEntity(),
      );
    } catch (e) {
      return Left<Failure, EmergencyReport?>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> resolveReport(EmergencyReportId id) async {
    try {
      await _remoteDatasource.resolveEmergencyReport(
        id: id.value,
        resolvedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }
}
