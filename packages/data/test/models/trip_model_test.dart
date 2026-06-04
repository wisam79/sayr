import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/models/trip_model.dart';

void main() {
  group('TripModel', () {
    test('fromJson and toEntity mapping', () {
      final json = {
        'id': 'trip-1',
        'route_id': 'route-1',
        'driver_id': 'driver-1',
        'status': 'in_transit',
        'scheduled_at': '2026-06-04T08:00:00.000Z',
        'started_at': '2026-06-04T08:05:00.000Z',
        'ended_at': '2026-06-04T08:45:00.000Z',
        'last_lat': 33.3,
        'last_lng': 44.4,
        'route_start_lat': 33.1,
        'route_start_lng': 44.1,
        'route_end_lat': 33.2,
        'route_end_lng': 44.2,
      };

      final model = TripModel.fromJson(json);
      expect(model.id, 'trip-1');
      expect(model.status, 'in_transit');

      final entity = model.toEntity();
      expect(entity.id, const TripId('trip-1'));
      expect(entity.status, TripStatus.inTransit);
      expect(entity.lastLocation,
          const Coordinates(latitude: 33.3, longitude: 44.4));
      expect(entity.routeStartLocation,
          const Coordinates(latitude: 33.1, longitude: 44.1));
      expect(entity.routeEndLocation,
          const Coordinates(latitude: 33.2, longitude: 44.2));
    });
  });
}
