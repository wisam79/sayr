import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the visibility of the password field in login page.
class LoginFormCubit extends Cubit<bool> {
  /// Constructor for [LoginFormCubit].
  LoginFormCubit() : super(true);

  /// Toggles the visibility state of the password field.
  void toggleVisibility() => emit(!state);
}
