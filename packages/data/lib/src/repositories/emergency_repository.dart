import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/emergency_report_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Concrete implementation of EmergencyRepository using Remote data source.
@LazySingleton(as: EmergencyRepository)
class EmergencyRepositoryImpl extends BaseRepository
    implements EmergencyRepository {
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
    return guard(() async {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
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

      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, EmergencyReport?>> getActiveReport() async {
    return guard(() async {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
      }

      final response =
          await _remoteDatasource.getActiveEmergencyReport(currentUserId);
      if (response == null) {
        return null;
      }

      // Map latitude and longitude properly for DTO
      final map = {
        ...response,
        'latitude': (response['latitude'] as num).toDouble(),
        'longitude': (response['longitude'] as num).toDouble(),
      };

      return EmergencyReportModel.fromJson(map).toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> resolveReport(EmergencyReportId id) async {
    return guard(() async {
      await _remoteDatasource.resolveEmergencyReport(
        id: id.value,
        resolvedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return unit;
    });
  }
}
