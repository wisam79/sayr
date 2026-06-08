import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';

/// Manages loading, error, and loaded state for a single route.
class RouteDetailsCubit extends Cubit<RouteDetailsState> {
  /// Creates a [RouteDetailsCubit] with the given [routeRepository].
  RouteDetailsCubit({required RouteRepository routeRepository})
      : _routeRepository = routeRepository,
        super(const RouteDetailsInitial());

  final RouteRepository _routeRepository;

  /// Loads the route details for the given [routeId].
  Future<void> loadRoute(RouteId routeId) async {
    emit(const RouteDetailsLoading());
    final result = await _routeRepository.getById(routeId);
    result.fold(
      (failure) => emit(RouteDetailsError(failure.message ?? '')),
      (route) => emit(RouteDetailsLoaded(route)),
    );
  }

  /// Sets the state to [RouteDetailsLoaded] with the given [route] directly.
  void setRoute(Route route) {
    emit(RouteDetailsLoaded(route));
  }
}

/// Base state class for route details.
sealed class RouteDetailsState {
  /// Constructor for [RouteDetailsState].
  const RouteDetailsState();
}

/// Initial state when route details have not been loaded.
class RouteDetailsInitial extends RouteDetailsState {
  /// Constructor for [RouteDetailsInitial].
  const RouteDetailsInitial();
}

/// State when route details are being loaded.
class RouteDetailsLoading extends RouteDetailsState {
  /// Constructor for [RouteDetailsLoading].
  const RouteDetailsLoading();
}

/// State when route details have loaded successfully.
class RouteDetailsLoaded extends RouteDetailsState {
  /// Constructor for [RouteDetailsLoaded].
  const RouteDetailsLoaded(this.route);

  /// The loaded route details.
  final Route route;
}

/// State when loading route details fails.
class RouteDetailsError extends RouteDetailsState {
  /// Constructor for [RouteDetailsError].
  const RouteDetailsError(this.message);

  /// The error message.
  final String message;
}
