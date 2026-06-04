import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

sealed class RoutesState extends Equatable {
  const RoutesState();

  @override
  List<Object?> get props => [];
}

class RoutesInitial extends RoutesState {
  const RoutesInitial();
}

class RoutesLoading extends RoutesState {
  const RoutesLoading();
}

class RoutesLoaded extends RoutesState {
  const RoutesLoaded(this.routes);
  final List<Route> routes;

  @override
  List<Object?> get props => [routes];
}

class RoutesError extends RoutesState {
  const RoutesError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
