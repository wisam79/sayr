import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the current bottom navigation tab index in the home page.
class HomeNavCubit extends Cubit<int> {
  /// Creates a [HomeNavCubit] with the default tab selected (index 0).
  HomeNavCubit() : super(0);

  /// Selects a new tab by emitting its [index].
  void selectTab(int index) => emit(index);
}
