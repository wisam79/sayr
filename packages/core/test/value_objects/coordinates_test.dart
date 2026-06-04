import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('Coordinates - validation', () {
    test('valid coordinates', () {
      const coords = Coordinates(latitude: 33.3152, longitude: 44.3661);
      expect(coords.isValid, isTrue);
    });

    test('invalid latitude (>90)', () {
      const coords = Coordinates(latitude: 91, longitude: 44.3661);
      expect(coords.isValid, isFalse);
    });

    test('invalid latitude (<-90)', () {
      const coords = Coordinates(latitude: -91, longitude: 44.3661);
      expect(coords.isValid, isFalse);
    });

    test('invalid longitude (>180)', () {
      const coords = Coordinates(latitude: 33.3152, longitude: 181);
      expect(coords.isValid, isFalse);
    });

    test('NaN coordinates are invalid', () {
      const coords = Coordinates(latitude: double.nan, longitude: 44);
      expect(coords.isValid, isFalse);
    });

    test('Infinity coordinates are invalid', () {
      const coords = Coordinates(latitude: double.infinity, longitude: 44);
      expect(coords.isValid, isFalse);
    });
  });

  group('Coordinates - distance calculation', () {
    test('Baghdad to Basra is approximately 440-500 km', () {
      // Baghdad: 33.3152, 44.3661
      // Basra:   30.5085, 47.7804
      const baghdad = Coordinates(latitude: 33.3152, longitude: 44.3661);
      const basra = Coordinates(latitude: 30.5085, longitude: 47.7804);
      final distance = baghdad.distanceToKm(basra);
      expect(distance, greaterThan(400));
      expect(distance, lessThan(550));
    });

    test('same coordinates have zero distance', () {
      const coords = Coordinates(latitude: 33.3152, longitude: 44.3661);
      expect(coords.distanceToMeters(coords), equals(0));
    });

    test('distance is symmetric', () {
      const a = Coordinates(latitude: 33.3152, longitude: 44.3661);
      const b = Coordinates(latitude: 33.4, longitude: 44.5);
      expect(a.distanceToMeters(b), closeTo(b.distanceToMeters(a), 0.001));
    });
  });

  group('Coordinates - bearing', () {
    test('bearing north returns ~0 degrees', () {
      const a = Coordinates(latitude: 33.0, longitude: 44.0);
      const b = Coordinates(latitude: 34.0, longitude: 44.0);
      expect(a.bearingTo(b), closeTo(0, 1));
    });

    test('bearing east returns ~90 degrees', () {
      const a = Coordinates(latitude: 33.0, longitude: 44.0);
      const b = Coordinates(latitude: 33.0, longitude: 45.0);
      expect(a.bearingTo(b), closeTo(90, 1));
    });
  });

  group('Coordinates - midpoint', () {
    test('midpoint of two coordinates is between them', () {
      const a = Coordinates(latitude: 33.0, longitude: 44.0);
      const b = Coordinates(latitude: 34.0, longitude: 45.0);
      final mid = a.midpoint(b);
      expect(mid.latitude, closeTo(33.5, 0.1));
      expect(mid.longitude, closeTo(44.5, 0.1));
    });
  });

  group('Coordinates - equality', () {
    test('equal coordinates are equal', () {
      const a = Coordinates(latitude: 33.3152, longitude: 44.3661);
      const b = Coordinates(latitude: 33.3152, longitude: 44.3661);
      expect(a, equals(b));
    });

    test('different coordinates are not equal', () {
      const a = Coordinates(latitude: 33.3152, longitude: 44.3661);
      const b = Coordinates(latitude: 33.3153, longitude: 44.3661);
      expect(a, isNot(equals(b)));
    });
  });
}
