import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/local_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/trip_model.dart';
import 'package:sayr_data/src/models/user_model.dart';

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

  @override
  Future<Either<Failure, PaymentInfo>> createPayment({
    required RouteId routeId,
    required int amount,
    required String currency,
    required String method,
  }) async {
    try {
      final response = await _remoteDatasource.createPayment(
        routeId: routeId.value,
        amount: amount,
        currency: currency,
        method: method,
      );
      return Right<Failure, PaymentInfo>(PaymentInfo.fromJson(response));
    } catch (e) {
      return Left<Failure, PaymentInfo>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentInfo>> getPaymentStatus(
    String paymentId,
  ) async {
    try {
      final response = await _remoteDatasource.getPaymentStatus(paymentId);
      if (response == null) {
        return const Left<Failure, PaymentInfo>(
          NotFoundFailure(resource: 'payment'),
        );
      }
      return Right<Failure, PaymentInfo>(PaymentInfo.fromJson(response));
    } catch (e) {
      return Left<Failure, PaymentInfo>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Driver>> getDriverById(DriverId id) async {
    try {
      final response = await _remoteDatasource.getDriverById(id.value);
      if (response == null) {
        return const Left<Failure, Driver>(NotFoundFailure(resource: 'driver'));
      }
      return Right<Failure, Driver>(_driverFromDb(response));
    } catch (e) {
      return Left<Failure, Driver>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getDriverProfile(UserId userId) async {
    try {
      final response =
          await _remoteDatasource.fetchCurrentProfile(userId.value);
      if (response == null) {
        return const Left<Failure, User>(NotFoundFailure(resource: 'profile'));
      }
      return Right<Failure, User>(UserModel.fromJson(response).toEntity());
    } catch (e) {
      return Left<Failure, User>(ServerFailure(message: e.toString()));
    }
  }

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

  Driver _driverFromDb(Map<String, dynamic> json) {
    return Driver(
      id: DriverId(json['id'] as String),
      userId: UserId(json['user_id'] as String),
      vehicleModel: json['vehicle_model'] as String,
      vehiclePlate: json['vehicle_plate'] as String,
      capacity: (json['capacity'] as num).toInt(),
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
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
