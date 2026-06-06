import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/reset_password_form_cubit.dart';

void main() {
  group('ResetPasswordFormCubit', () {
    test('initial state has both obscure flags as true', () {
      final cubit = ResetPasswordFormCubit();
      expect(cubit.state.obscurePassword, isTrue);
      expect(cubit.state.obscureConfirm, isTrue);
    });

    blocTest<ResetPasswordFormCubit,
        ({bool obscurePassword, bool obscureConfirm})>(
      'togglePasswordVisibility flips only password flag',
      build: ResetPasswordFormCubit.new,
      act: (cubit) => cubit.togglePasswordVisibility(),
      verify: (cubit) {
        expect(cubit.state.obscurePassword, isFalse);
        expect(cubit.state.obscureConfirm, isTrue);
      },
    );

    blocTest<ResetPasswordFormCubit,
        ({bool obscurePassword, bool obscureConfirm})>(
      'toggleConfirmVisibility flips only confirm flag',
      build: ResetPasswordFormCubit.new,
      act: (cubit) => cubit.toggleConfirmVisibility(),
      verify: (cubit) {
        expect(cubit.state.obscurePassword, isTrue);
        expect(cubit.state.obscureConfirm, isFalse);
      },
    );
  });
}
