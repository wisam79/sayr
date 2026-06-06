import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the current page and page controller of the onboarding flow.
class OnboardingCubit extends Cubit<int> {
  /// Constructor for [OnboardingCubit].
  OnboardingCubit() : super(0);

  /// Sets the active page index.
  void setPage(int index) => emit(index);
}
