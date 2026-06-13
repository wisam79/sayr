import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/user_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

@LazySingleton(as: DriverRepository)
class DriverRepositoryImpl extends BaseRepository implements DriverRepository {
  DriverRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required super.talker,
  }) : _remoteDatasource = remoteDatasource;

  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, Driver>> getDriverById(DriverId id) async {
    return guard(() async {
      final response = await _remoteDatasource.getDriverById(id.value);
      if (response == null) {
        throw const NotFoundFailure(resource: 'driver');
      }
      return _driverFromDb(response);
    });
  }

  @override
  Future<Either<Failure, User>> getDriverProfile(UserId userId) async {
    return guard(() async {
      final response =
          await _remoteDatasource.fetchCurrentProfile(userId.value);
      if (response == null) {
        throw const NotFoundFailure(resource: 'profile');
      }
      return UserModel.fromJson(response).toEntity();
    });
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
