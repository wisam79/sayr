import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('Failure sealed class hierarchy', () {
    group('NetworkFailure', () {
      test('equality with same message', () {
        const a = NetworkFailure(message: 'offline');
        const b = NetworkFailure(message: 'offline');
        expect(a, equals(b));
      });

      test('inequality with different message', () {
        const a = NetworkFailure(message: 'offline');
        const b = NetworkFailure(message: 'timeout');
        expect(a, isNot(equals(b)));
      });

      test('default message is null', () {
        const failure = NetworkFailure();
        expect(failure.message, isNull);
      });
    });

    group('ServerFailure', () {
      test('preserves statusCode in props', () {
        const failure = ServerFailure(message: 'err', statusCode: 500);
        expect(failure.statusCode, 500);
        expect(failure.props, ['err', 500]);
      });

      test('equality includes statusCode', () {
        const a = ServerFailure(message: 'err', statusCode: 500);
        const b = ServerFailure(message: 'err', statusCode: 502);
        expect(a, isNot(equals(b)));
      });

      test('statusCode defaults to null', () {
        const failure = ServerFailure(message: 'err');
        expect(failure.statusCode, isNull);
      });
    });

    group('UnauthorizedFailure', () {
      test('has correct props', () {
        const failure = UnauthorizedFailure(message: '401');
        expect(failure.message, '401');
        expect(failure.props, ['401']);
      });
    });

    group('ForbiddenFailure', () {
      test('has correct props', () {
        const failure = ForbiddenFailure(message: '403');
        expect(failure.message, '403');
      });
    });

    group('NotFoundFailure', () {
      test('preserves resource in props', () {
        const failure = NotFoundFailure(
          message: 'missing',
          resource: 'license',
        );
        expect(failure.resource, 'license');
        expect(failure.props, ['missing', 'license']);
      });

      test('resource defaults to null', () {
        const failure = NotFoundFailure(message: 'gone');
        expect(failure.resource, isNull);
      });
    });

    group('ValidationFailure', () {
      test('preserves errors list', () {
        const failure = ValidationFailure(
          message: 'invalid',
          errors: ['field1 required', 'field2 too short'],
        );
        expect(failure.errors, hasLength(2));
        expect(failure.errors.first, 'field1 required');
      });

      test('errors default to empty list', () {
        const failure = ValidationFailure(message: 'invalid');
        expect(failure.errors, isEmpty);
      });

      test('equality includes errors list', () {
        const a = ValidationFailure(
          message: 'x',
          errors: ['a'],
        );
        const b = ValidationFailure(
          message: 'x',
          errors: ['b'],
        );
        expect(a, isNot(equals(b)));
      });
    });

    group('RateLimitFailure', () {
      test('preserves retryAfter', () {
        const failure = RateLimitFailure(message: 'slow', retryAfter: 30);
        expect(failure.retryAfter, 30);
        expect(failure.props, ['slow', 30]);
      });

      test('retryAfter defaults to null', () {
        const failure = RateLimitFailure(message: 'slow');
        expect(failure.retryAfter, isNull);
      });
    });

    group('CacheFailure', () {
      test('has correct props', () {
        const failure = CacheFailure(message: 'disk full');
        expect(failure.message, 'disk full');
      });
    });

    group('BusinessRuleFailure', () {
      test('requires message', () {
        const failure = BusinessRuleFailure(message: 'already subscribed');
        expect(failure.message, 'already subscribed');
      });
    });

    group('InvalidStateTransitionFailure', () {
      test('preserves from and event', () {
        const failure = InvalidStateTransitionFailure(
          message: 'cannot complete',
          from: 'scheduled',
          event: 'complete',
        );
        expect(failure.from, 'scheduled');
        expect(failure.event, 'complete');
        expect(failure.props, ['cannot complete', 'scheduled', 'complete']);
      });

      test('from and event default to null', () {
        const failure = InvalidStateTransitionFailure(message: 'bad');
        expect(failure.from, isNull);
        expect(failure.event, isNull);
      });
    });

    group('LocationFailure', () {
      test('preserves isPermissionDenied in props', () {
        const failure = LocationFailure(
          message: 'permission denied',
          isPermissionDenied: true,
        );
        expect(failure.isPermissionDenied, isTrue);
        expect(failure.props, ['permission denied', true]);
      });

      test('isPermissionDenied defaults to false', () {
        const failure = LocationFailure(message: 'gps off');
        expect(failure.isPermissionDenied, isFalse);
      });
    });

    group('UnknownFailure', () {
      test('has correct props', () {
        const failure = UnknownFailure(message: 'unexpected');
        expect(failure.message, 'unexpected');
      });
    });

    test('toString includes message', () {
      const failure = ServerFailure(message: 'test error');
      expect(failure.toString(), contains('test error'));
    });

    test('Failure subtypes are distinct types', () {
      const network = NetworkFailure();
      const server = ServerFailure();
      const unauthorized = UnauthorizedFailure();

      expect(network, isA<NetworkFailure>());
      expect(network, isNot(isA<ServerFailure>()));
      expect(server, isNot(isA<UnauthorizedFailure>()));
      expect(unauthorized, isNot(isA<ForbiddenFailure>()));
    });

    test('all subtypes implement Exception', () {
      const failures = <Failure>[
        NetworkFailure(),
        ServerFailure(),
        UnauthorizedFailure(),
        ForbiddenFailure(),
        NotFoundFailure(),
        ValidationFailure(),
        RateLimitFailure(),
        CacheFailure(),
        BusinessRuleFailure(message: 'x'),
        InvalidStateTransitionFailure(),
        LocationFailure(),
        UnknownFailure(),
      ];

      for (final failure in failures) {
        expect(failure, isA<Exception>(), reason: '${failure.runtimeType}');
      }
    });
  });
}
