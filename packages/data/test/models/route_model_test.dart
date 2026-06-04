import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/route_model.dart';

void main() {
  group('RouteModel', () {
    test('fromJson creates valid RouteModel', () {
      final json = {
        'id': 'route-1',
        'driver_id': 'driver-1',
        'title': 'جامعة بغداد - الكرادة',
        'start_location': 'جامعة بغداد',
        'end_location': 'الكرادة',
        'price': 50000,
        'capacity': 40,
        'available_seats': 15,
        'is_active': true,
        'institution_id': 'inst-1',
        'start_lat': 33.3128,
        'start_lng': 44.3615,
        'end_lat': 33.3152,
        'end_lng': 44.4017,
        'departure_time': '08:00',
        'return_time': '15:00',
        'days_of_week': ['sun', 'mon', 'tue', 'wed', 'thu'],
      };

      final model = RouteModel.fromJson(json);

      expect(model.id, 'route-1');
      expect(model.driverId, 'driver-1');
      expect(model.title, 'جامعة بغداد - الكرادة');
      expect(model.startLocation, 'جامعة بغداد');
      expect(model.endLocation, 'الكرادة');
      expect(model.price, 50000);
      expect(model.capacity, 40);
      expect(model.availableSeats, 15);
      expect(model.isActive, true);
      expect(model.institutionId, 'inst-1');
      expect(model.startLat, 33.3128);
      expect(model.startLng, 44.3615);
      expect(model.endLat, 33.3152);
      expect(model.endLng, 44.4017);
      expect(model.departureTime, '08:00');
      expect(model.returnTime, '15:00');
      expect(model.daysOfWeek, ['sun', 'mon', 'tue', 'wed', 'thu']);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'route-2',
        'driver_id': 'driver-2',
        'title': 'خط بسيط',
        'start_location': 'النهاية الأولى',
        'end_location': 'النهاية الثانية',
        'price': 30000,
        'capacity': 20,
        'available_seats': 20,
      };

      final model = RouteModel.fromJson(json);

      expect(model.id, 'route-2');
      expect(model.isActive, true);
      expect(model.institutionId, isNull);
      expect(model.startLat, isNull);
      expect(model.startLng, isNull);
      expect(model.departureTime, isNull);
      expect(model.returnTime, isNull);
      expect(model.daysOfWeek, isEmpty);
    });

    test('toEntity converts to domain Route', () {
      final model = RouteModel(
        id: 'route-3',
        driverId: 'driver-3',
        title: 'خط التحويل',
        startLocation: 'A',
        endLocation: 'B',
        price: 25000,
        capacity: 30,
        availableSeats: 10,
        isActive: true,
        startLat: 33.0,
        startLng: 44.0,
        endLat: 33.1,
        endLng: 44.1,
        departureTime: '09:00',
        returnTime: '17:00',
        daysOfWeek: ['sun', 'wed'],
      );

      final entity = model.toEntity();

      expect(entity.id, RouteId('route-3'));
      expect(entity.driverId, DriverId('driver-3'));
      expect(entity.title, 'خط التحويل');
      expect(entity.startLocation, 'A');
      expect(entity.endLocation, 'B');
      expect(entity.price, const Money(25000));
      expect(entity.capacity, 30);
      expect(entity.availableSeats, 10);
      expect(entity.isActive, true);
      expect(entity.startCoordinates,
          Coordinates(latitude: 33.0, longitude: 44.0));
      expect(
          entity.endCoordinates, Coordinates(latitude: 33.1, longitude: 44.1));
      expect(entity.departureTime, '09:00');
      expect(entity.returnTime, '17:00');
      expect(entity.daysOfWeek, ['sun', 'wed']);
    });

    test('toEntity with no coordinates returns null coordinates', () {
      final model = RouteModel(
        id: 'route-4',
        driverId: 'driver-4',
        title: 'بدون إحداثيات',
        startLocation: 'A',
        endLocation: 'B',
        price: 10000,
        capacity: 10,
        availableSeats: 10,
        isActive: false,
      );

      final entity = model.toEntity();

      expect(entity.startCoordinates, isNull);
      expect(entity.endCoordinates, isNull);
      expect(entity.isActive, false);
    });
  });
}
