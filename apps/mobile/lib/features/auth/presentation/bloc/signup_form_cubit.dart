import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the visibility of the password field in signup page.
class SignupFormCubit extends Cubit<bool> {
  /// Constructor for [SignupFormCubit].
  SignupFormCubit() : super(true);

  /// Toggles the visibility state of the password field.
  void toggleVisibility() => emit(!state);
}
