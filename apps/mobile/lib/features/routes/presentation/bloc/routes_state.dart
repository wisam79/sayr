import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';

/// Base class for routes states.
sealed class RoutesState extends Equatable {
  /// Constructor for [RoutesState].
  const RoutesState();

  @override
  List<Object?> get props => [];
}

/// Initial routes state before load starts.
class RoutesInitial extends RoutesState {
  /// Constructor for [RoutesInitial].
  const RoutesInitial();
}

/// State when routes list is being fetched.
class RoutesLoading extends RoutesState {
  /// Constructor for [RoutesLoading].
  const RoutesLoading();
}

/// State when active routes list has successfully loaded.
class RoutesLoaded extends RoutesState {
  /// Constructor for [RoutesLoaded].
  const RoutesLoaded(this.routes);

  /// Loaded list of active routes.
  final List<Route> routes;

  @override
  List<Object?> get props => [routes];
}

/// State when loading routes fails.
class RoutesError extends RoutesState {
  /// Constructor for [RoutesError].
  const RoutesError(this.failure);

  /// Error information.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
