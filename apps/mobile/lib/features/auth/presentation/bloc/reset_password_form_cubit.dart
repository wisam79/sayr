import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the visibility of password and confirmation fields
/// in the reset password page.
class ResetPasswordFormCubit
    extends Cubit<({bool obscurePassword, bool obscureConfirm})> {
  /// Constructor for [ResetPasswordFormCubit].
  ResetPasswordFormCubit()
      : super((obscurePassword: true, obscureConfirm: true));

  /// Toggles the visibility state of the password field.
  void togglePasswordVisibility() => emit(
        (
          obscurePassword: !state.obscurePassword,
          obscureConfirm: state.obscureConfirm,
        ),
      );

  /// Toggles the visibility state of the password confirmation field.
  void toggleConfirmVisibility() => emit(
        (
          obscurePassword: state.obscurePassword,
          obscureConfirm: !state.obscureConfirm,
        ),
      );
}
