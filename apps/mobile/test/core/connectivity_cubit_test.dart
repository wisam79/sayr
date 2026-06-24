import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_mobile/core/connectivity_cubit.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityCubit', () {
    late MockConnectivity mockConnectivity;
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() {
      mockConnectivity = MockConnectivity();
      connectivityController =
          StreamController<List<ConnectivityResult>>.broadcast();
      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => connectivityController.stream);
    });

    tearDown(() {
      connectivityController.close();
    });

    test('initial state is false (online)', () {
      final cubit = ConnectivityCubit(connectivity: mockConnectivity);
      expect(cubit.state, isFalse);
      cubit.close();
    });

    test('emits true when connectivity result is empty or none (offline)',
        () async {
      final cubit = ConnectivityCubit(connectivity: mockConnectivity);
      final states = <bool>[];
      final subscription = cubit.stream.listen(states.add);

      // Simulate offline results
      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(states, contains(true));

      // Simulate empty list
      connectivityController.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isTrue);

      await subscription.cancel();
      await cubit.close();
    });

    test('emits false when connectivity becomes active (online)', () async {
      final cubit = ConnectivityCubit(connectivity: mockConnectivity);
      final states = <bool>[];
      final subscription = cubit.stream.listen(states.add);

      // Move to offline first
      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      // Move back to online
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(states, [true, false]);
      expect(cubit.state, isFalse);

      await subscription.cancel();
      await cubit.close();
    });
  });
}
