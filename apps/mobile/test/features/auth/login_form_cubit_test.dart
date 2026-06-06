import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/login_form_cubit.dart';

void main() {
  group('LoginFormCubit', () {
    test('initial state is true (password obscured)', () {
      final cubit = LoginFormCubit();
      expect(cubit.state, isTrue);
    });

    blocTest<LoginFormCubit, bool>(
      'emits false when toggleVisibility is called',
      build: LoginFormCubit.new,
      act: (cubit) => cubit.toggleVisibility(),
      expect: () => [false],
    );

    blocTest<LoginFormCubit, bool>(
      'toggles back to true on second call',
      build: LoginFormCubit.new,
      act: (cubit) => cubit
        ..toggleVisibility()
        ..toggleVisibility(),
      expect: () => [false, true],
    );
  });
}
