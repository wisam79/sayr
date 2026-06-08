import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/user_model.dart';

/// Concrete implementation of [DriverRepository] using the remote datasource.
@LazySingleton(as: DriverRepository)
class DriverRepositoryImpl implements DriverRepository {
  DriverRepositoryImpl({required RemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  final RemoteDatasource _remoteDatasource;

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
}
