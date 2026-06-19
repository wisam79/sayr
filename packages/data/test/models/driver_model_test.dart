import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/driver_model.dart';

void main() {
  group('DriverModel', () {
    test('fromJson creates valid DriverModel', () {
      final json = {
        'id': 'drv-1',
        'user_id': 'user-1',
        'vehicle_model': 'Toyota Hiace',
        'vehicle_plate': '12345 بغداد',
        'capacity': 14,
        'is_verified': true,
        'rating': 4.5,
      };

      final model = DriverModel.fromJson(json);

      expect(model.id, 'drv-1');
      expect(model.userId, 'user-1');
      expect(model.vehicleModel, 'Toyota Hiace');
      expect(model.vehiclePlate, '12345 بغداد');
      expect(model.capacity, 14);
      expect(model.isVerified, true);
      expect(model.rating, 4.5);
    });

    test('fromJson applies defaults for optional fields', () {
      final json = {
        'id': 'drv-2',
        'user_id': 'user-2',
        'vehicle_model': 'Kia',
        'vehicle_plate': '99999',
        'capacity': 8,
      };

      final model = DriverModel.fromJson(json);

      expect(model.isVerified, false);
      expect(model.rating, 0.0);
    });

    test('toEntity converts to domain Driver', () {
      const model = DriverModel(
        id: 'drv-3',
        userId: 'user-3',
        vehicleModel: 'Mercedes Sprinter',
        vehiclePlate: '77777 بصرة',
        capacity: 20,
        isVerified: true,
        rating: 4.8,
      );

      final entity = model.toEntity();

      expect(entity.id, const DriverId('drv-3'));
      expect(entity.userId, const UserId('user-3'));
      expect(entity.vehicleModel, 'Mercedes Sprinter');
      expect(entity.vehiclePlate, '77777 بصرة');
      expect(entity.capacity, 20);
      expect(entity.isVerified, true);
      expect(entity.rating, 4.8);
    });
  });
}
