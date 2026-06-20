import 'package:sayr_core/sayr_core.dart';
import 'package:test/test.dart';

void main() {
  group('TripStateMachine - valid transitions', () {
    test('scheduled → driverWaiting via arrive', () {
      final result = TripStateMachine.transition(
        TripStatus.scheduled,
        TripEvent.arrive,
      );
      expect(result, equals(TripStatus.driverWaiting));
    });

    test('scheduled → absent via markAbsent', () {
      final result = TripStateMachine.transition(
        TripStatus.scheduled,
        TripEvent.markAbsent,
      );
      expect(result, equals(TripStatus.absent));
    });

    test('scheduled → cancelled via cancel', () {
      final result = TripStateMachine.transition(
        TripStatus.scheduled,
        TripEvent.cancel,
      );
      expect(result, equals(TripStatus.cancelled));
    });

    test('driverWaiting → inTransit via start', () {
      final result = TripStateMachine.transition(
        TripStatus.driverWaiting,
        TripEvent.start,
      );
      expect(result, equals(TripStatus.inTransit));
    });

    test('driverWaiting → absent via markAbsent', () {
      final result = TripStateMachine.transition(
        TripStatus.driverWaiting,
        TripEvent.markAbsent,
      );
      expect(result, equals(TripStatus.absent));
    });

    test('driverWaiting → cancelled via cancel', () {
      final result = TripStateMachine.transition(
        TripStatus.driverWaiting,
        TripEvent.cancel,
      );
      expect(result, equals(TripStatus.cancelled));
    });

    test('inTransit → completed via complete', () {
      final result = TripStateMachine.transition(
        TripStatus.inTransit,
        TripEvent.complete,
      );
      expect(result, equals(TripStatus.completed));
    });

    test('inTransit → cancelled via cancel', () {
      final result = TripStateMachine.transition(
        TripStatus.inTransit,
        TripEvent.cancel,
      );
      expect(result, equals(TripStatus.cancelled));
    });

    test('absent → cancelled via cancel', () {
      final result = TripStateMachine.transition(
        TripStatus.absent,
        TripEvent.cancel,
      );
      expect(result, equals(TripStatus.cancelled));
    });
  });

  group('TripStateMachine - invalid transitions (must return null)', () {
    test('scheduled → completed (cannot skip to complete)', () {
      final result = TripStateMachine.transition(
        TripStatus.scheduled,
        TripEvent.complete,
      );
      expect(result, isNull);
    });

    test('scheduled → inTransit (must go through driverWaiting)', () {
      final result = TripStateMachine.transition(
        TripStatus.scheduled,
        TripEvent.start,
      );
      expect(result, isNull);
    });

    test('inTransit → absent (NOT ALLOWED in business rules)', () {
      final result = TripStateMachine.transition(
        TripStatus.inTransit,
        TripEvent.markAbsent,
      );
      expect(result, isNull);
    });

    test('inTransit → scheduled (cannot go back)', () {
      final result = TripStateMachine.transition(
        TripStatus.inTransit,
        TripEvent.arrive,
      );
      expect(result, isNull);
    });

    test('completed is terminal - no transitions', () {
      for (final event in [
        TripEvent.arrive,
        TripEvent.start,
        TripEvent.complete,
        TripEvent.markAbsent,
        TripEvent.cancel,
      ]) {
        final result = TripStateMachine.transition(TripStatus.completed, event);
        expect(result, isNull, reason: 'completed is terminal: $event');
      }
    });

    test('cancelled is terminal - no transitions', () {
      for (final event in [
        TripEvent.arrive,
        TripEvent.start,
        TripEvent.complete,
        TripEvent.markAbsent,
        TripEvent.cancel,
      ]) {
        final result = TripStateMachine.transition(TripStatus.cancelled, event);
        expect(result, isNull, reason: 'cancelled is terminal: $event');
      }
    });

    test('absent cannot go to inTransit directly', () {
      final result = TripStateMachine.transition(
        TripStatus.absent,
        TripEvent.start,
      );
      expect(result, isNull);
    });

    test('absent cannot go back to scheduled', () {
      final result = TripStateMachine.transition(
        TripStatus.absent,
        TripEvent.arrive,
      );
      expect(result, isNull);
    });
  });

  group('TripStateMachine - canTransition', () {
    test('returns true for valid transitions', () {
      expect(
        TripStateMachine.canTransition(
          TripStatus.scheduled,
          TripEvent.arrive,
        ),
        isTrue,
      );
      expect(
        TripStateMachine.canTransition(
          TripStatus.inTransit,
          TripEvent.complete,
        ),
        isTrue,
      );
    });

    test('returns false for invalid transitions', () {
      expect(
        TripStateMachine.canTransition(
          TripStatus.completed,
          TripEvent.cancel,
        ),
        isFalse,
      );
      expect(
        TripStateMachine.canTransition(
          TripStatus.scheduled,
          TripEvent.complete,
        ),
        isFalse,
      );
    });
  });

  group('TripStateMachine - isTerminal', () {
    test('completed is terminal', () {
      expect(TripStateMachine.isTerminal(TripStatus.completed), isTrue);
    });

    test('cancelled is terminal', () {
      expect(TripStateMachine.isTerminal(TripStatus.cancelled), isTrue);
    });

    test('scheduled is not terminal', () {
      expect(TripStateMachine.isTerminal(TripStatus.scheduled), isFalse);
    });

    test('driverWaiting is not terminal', () {
      expect(TripStateMachine.isTerminal(TripStatus.driverWaiting), isFalse);
    });

    test('inTransit is not terminal', () {
      expect(TripStateMachine.isTerminal(TripStatus.inTransit), isFalse);
    });

    test('absent is not terminal (can be cancelled)', () {
      expect(TripStateMachine.isTerminal(TripStatus.absent), isFalse);
    });
  });

  group('TripStateMachine - validEventsFrom', () {
    test('scheduled has 3 valid events', () {
      final events = TripStateMachine.validEventsFrom(TripStatus.scheduled);
      expect(events, hasLength(3));
      expect(
        events,
        containsAll(
          [TripEvent.arrive, TripEvent.markAbsent, TripEvent.cancel],
        ),
      );
    });

    test('completed has no valid events', () {
      final events = TripStateMachine.validEventsFrom(TripStatus.completed);
      expect(events, isEmpty);
    });

    test('cancelled has no valid events', () {
      final events = TripStateMachine.validEventsFrom(TripStatus.cancelled);
      expect(events, isEmpty);
    });
  });

  group('TripStateMachine - validNextStates', () {
    test('scheduled has 3 valid next states', () {
      final states = TripStateMachine.validNextStates(TripStatus.scheduled);
      expect(states, hasLength(3));
      expect(
        states,
        containsAll([
          TripStatus.driverWaiting,
          TripStatus.absent,
          TripStatus.cancelled,
        ]),
      );
    });

    test('driverWaiting has 3 valid next states', () {
      final states = TripStateMachine.validNextStates(TripStatus.driverWaiting);
      expect(states, hasLength(3));
      expect(
        states,
        containsAll([
          TripStatus.inTransit,
          TripStatus.absent,
          TripStatus.cancelled,
        ]),
      );
    });

    test('inTransit has 2 valid next states', () {
      final states = TripStateMachine.validNextStates(TripStatus.inTransit);
      expect(states, hasLength(2));
      expect(
        states,
        containsAll([
          TripStatus.completed,
          TripStatus.cancelled,
        ]),
      );
    });

    test('absent has 1 valid next state', () {
      final states = TripStateMachine.validNextStates(TripStatus.absent);
      expect(states, hasLength(1));
      expect(states, contains(TripStatus.cancelled));
    });

    test('completed has no valid next states', () {
      final states = TripStateMachine.validNextStates(TripStatus.completed);
      expect(states, isEmpty);
    });

    test('cancelled has no valid next states', () {
      final states = TripStateMachine.validNextStates(TripStatus.cancelled);
      expect(states, isEmpty);
    });
  });
}
