import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/trip_model.dart';

/// Concrete implementation of TripRepository using Remote and Local data sources.
@LazySingleton(as: TripRepository)
class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;
  final RemoteDatasource _remoteDatasource;
  final LocalDatasource _localDatasource;
  final Logger _logger = Logger();

  @override
  Future<Either<Failure, List<Trip>>> getActiveTrips() async {
    try {
      final response = await _remoteDatasource.getActiveTrips();
      final trips =
          response.map((json) => TripModel.fromJson(json).toEntity()).toList();
      try {
        await _localDatasource.cacheTrips(trips);
      } catch (e, st) {
        _logger.w(
          'Failed to cache active trips; serving from network only',
          error: e,
          stackTrace: st,
        );
      }
      return Right<Failure, List<Trip>>(trips);
    } catch (e) {
      try {
        final cached = await _localDatasource.getCachedTrips();
        if (cached.isNotEmpty) {
          return Right<Failure, List<Trip>>(cached);
        }
      } catch (cacheError, st) {
        _logger.w(
          'Failed to read cached trips during offline fallback',
          error: cacheError,
          stackTrace: st,
        );
      }
      return Left<Failure, List<Trip>>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Trip>> createTrip({
    required RouteId routeId,
    required DateTime scheduledAt,
  }) async {
    try {
      final tripId = await _remoteDatasource.createTrip(
        routeId: routeId.value,
        scheduledAt: scheduledAt,
      );
      final response = await _remoteDatasource.getTripById(tripId);
      if (response == null) {
        return const Left<Failure, Trip>(NotFoundFailure(resource: 'trip'));
      }
      return Right<Failure, Trip>(TripModel.fromJson(response).toEntity());
    } catch (e) {
      return Left<Failure, Trip>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Trip> watchTrip(TripId tripId) {
    return _remoteDatasource.watchTrip(tripId.value).map((rows) {
      if (rows.isEmpty) {
        throw StateError('Trip $tripId not found');
      }
      return TripModel.fromJson(rows.first).toEntity();
    });
  }

  @override
  Future<Either<Failure, Trip>> getById(TripId id) async {
    try {
      final response = await _remoteDatasource.getTripById(id.value);
      if (response == null) {
        return const Left<Failure, Trip>(NotFoundFailure(resource: 'trip'));
      }
      return Right<Failure, Trip>(TripModel.fromJson(response).toEntity());
    } catch (e) {
      try {
        final cached = await _localDatasource.getCachedTrips();
        final trip = cached.firstWhere((t) => t.id == id);
        return Right<Failure, Trip>(trip);
      } catch (cacheError, st) {
        _logger.w(
          'Failed to read cached trip during offline fallback',
          error: cacheError,
          stackTrace: st,
        );
      }
      return Left<Failure, Trip>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Trip>> updateStatus({
    required TripId tripId,
    required TripEvent event,
    Coordinates? location,
  }) async {
    final current = await getById(tripId);
    return current.fold<Future<Either<Failure, Trip>>>(
      (Failure failure) async => Left<Failure, Trip>(failure),
      (Trip trip) async {
        final newStatus = TripStateMachine.transition(trip.status, event);
        if (newStatus == null) {
          return Left<Failure, Trip>(
            InvalidStateTransitionFailure(
              from: trip.status.name,
              event: event.name,
            ),
          );
        }
        try {
          final response = await _remoteDatasource.updateTripStatus(
            tripId: tripId.value,
            newStatus: _statusToDb(newStatus),
            lat: location?.latitude,
            lng: location?.longitude,
          );
          return Right<Failure, Trip>(TripModel.fromJson(response).toEntity());
        } catch (e) {
          return Left<Failure, Trip>(ServerFailure(message: e.toString()));
        }
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> updateLocation({
    required TripId tripId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _remoteDatasource.updateTripLocation(
        tripId: tripId.value,
        lat: lat,
        lng: lng,
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      try {
        await _localDatasource.enqueueLocation(
          tripId: tripId.value,
          latitude: lat,
          longitude: lng,
        );
        return const Right<Failure, Unit>(unit);
      } catch (dbErr) {
        return Left<Failure, Unit>(ServerFailure(message: dbErr.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> updateBleOtp({
    required TripId tripId,
    required String otp,
    required DateTime expiresAt,
  }) async {
    try {
      await _remoteDatasource.updateTripBleOtp(
        tripId: tripId.value,
        otp: otp,
        expiresAt: expiresAt.toUtc().toIso8601String(),
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> bulkUpdateLocations(
    List<
            ({
              TripId tripId,
              double lat,
              double lng,
            })>
        locations,
  ) async {
    try {
      final locationsJson = locations
          .map(
            (l) => {
              'trip_id': l.tripId.value,
              'lat': l.lat,
              'lng': l.lng,
            },
          )
          .toList();

      await _remoteDatasource.bulkUpdateTripLocations(locationsJson);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  String _statusToDb(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.driverWaiting:
        return 'driver_waiting';
      case TripStatus.inTransit:
        return 'in_transit';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.absent:
        return 'absent';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }
}
