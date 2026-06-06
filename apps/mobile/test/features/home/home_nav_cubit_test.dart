import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/home/presentation/bloc/home_nav_cubit.dart';

void main() {
  group('HomeNavCubit', () {
    test('initial state is 0', () {
      final cubit = HomeNavCubit();
      expect(cubit.state, 0);
    });

    blocTest<HomeNavCubit, int>(
      'emits new index when selectTab is called',
      build: HomeNavCubit.new,
      act: (cubit) => cubit.selectTab(2),
      expect: () => [2],
    );

    blocTest<HomeNavCubit, int>(
      'emits updated index on each call',
      build: HomeNavCubit.new,
      act: (cubit) => cubit
        ..selectTab(1)
        ..selectTab(3)
        ..selectTab(0),
      expect: () => [1, 3, 0],
    );
  });
}
