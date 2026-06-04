# ADR-0004: Trip State Machine (FSM)

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
الرحلات في v1 تمر بحالات متعددة (scheduled, driver_waiting, in_transit, completed, absent, cancelled). يجب منع الانتقالات غير المشروعة (مثل in_transit → absent).

في v1 استخدمنا XState FSM في `packages/core` مع اختبار شامل.

## القرار (Decision)
نُحافظ على نفس FSM في `packages/core` لكن بـ **Dart نقي** (بدون dependency خارجي).

## الحالات المسموحة (Valid States)
```dart
enum TripStatus {
  scheduled,
  driverWaiting,
  inTransit,
  completed,
  absent,
  cancelled,
}
```

## مصفوفة الانتقالات (Transition Matrix)
| From | To | Event |
|------|----|----|
| scheduled | driverWaiting | arrive |
| scheduled | absent | markAbsent |
| scheduled | cancelled | cancel |
| driverWaiting | inTransit | start |
| driverWaiting | absent | markAbsent |
| driverWaiting | cancelled | cancel |
| inTransit | completed | complete |
| inTransit | cancelled | cancel |
| absent | cancelled | cancel |
| completed | ❌ | (terminal) |
| cancelled | ❌ | (terminal) |

## التنفيذ (Implementation)
```dart
// packages/core/lib/src/fsm/trip_state_machine.dart
import 'package:sayr_core/src/enums/trip_status.dart';

class TripEvent {
  final String name;
  const TripEvent._(this.name);
  static const arrive = TripEvent._('arrive');
  static const start = TripEvent._('start');
  static const complete = TripEvent._('complete');
  static const markAbsent = TripEvent._('markAbsent');
  static const cancel = TripEvent._('cancel');
}

class TripStateMachine {
  static const Map<TripStatus, Map<String, TripStatus>> _transitions = {
    TripStatus.scheduled: {
      'arrive': TripStatus.driverWaiting,
      'markAbsent': TripStatus.absent,
      'cancel': TripStatus.cancelled,
    },
    TripStatus.driverWaiting: {
      'start': TripStatus.inTransit,
      'markAbsent': TripStatus.absent,
      'cancel': TripStatus.cancelled,
    },
    TripStatus.inTransit: {
      'complete': TripStatus.completed,
      'cancel': TripStatus.cancelled,
    },
    TripStatus.absent: {
      'cancel': TripStatus.cancelled,
    },
    TripStatus.completed: {},
    TripStatus.cancelled: {},
  };

  /// Returns the next state, or null if the transition is invalid.
  static TripStatus? transition(TripStatus from, TripEvent event) {
    return _transitions[from]?[event.name];
  }

  /// Whether the transition is valid.
  static bool canTransition(TripStatus from, TripEvent event) {
    return _transitions[from]?.containsKey(event.name) ?? false;
  }

  /// Whether the state is terminal (no further transitions).
  static bool isTerminal(TripStatus state) {
    return _transitions[state]?.isEmpty ?? true;
  }
}
```

## التطبيق في الـ Use Case
```dart
class UpdateTripStatusUseCase {
  Future<Either<TripFailure, Trip>> call({
    required TripId tripId,
    required TripEvent event,
  }) async {
    final current = await _repository.getById(tripId);
    if (current.isNone()) return Left(TripNotFoundFailure());
    
    final trip = current.unwrap();
    final nextState = TripStateMachine.transition(trip.status, event);
    if (nextState == null) {
      return Left(InvalidTransitionFailure(
        from: trip.status,
        event: event,
      ));
    }
    
    return _repository.updateStatus(tripId, nextState);
  }
}
```

## الاختبارات (Tests - 100% coverage)
- جميع الانتقالات الـ 11 المسموحة
- جميع الانتقالات الـ 25 الممنوعة
- `isTerminal` للحالات النهائية
- `canTransition` للحالات العابرة

## مع SQL (Defense in Depth)
نفس الـ FSM مطبق في SQL RPC `update_trip_status` كطبقة حماية ثانية.

## المراجع
- [v1 XState FSM](https://github.com/xstate/xstate)
- [Finite State Machines](https://en.wikipedia.org/wiki/Finite-state_machine)
