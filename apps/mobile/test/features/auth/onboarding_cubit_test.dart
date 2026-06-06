import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/onboarding_cubit.dart';

void main() {
  group('OnboardingCubit', () {
    test('initial state is 0', () {
      final cubit = OnboardingCubit();
      expect(cubit.state, 0);
    });

    blocTest<OnboardingCubit, int>(
      'setPage updates the page index',
      build: OnboardingCubit.new,
      act: (cubit) => cubit
        ..setPage(1)
        ..setPage(2),
      expect: () => [1, 2],
    );
  });
}
