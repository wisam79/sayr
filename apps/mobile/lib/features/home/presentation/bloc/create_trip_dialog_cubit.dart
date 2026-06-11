import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';

/// Manages the state of the create-trip dialog (form).
class CreateTripDialogCubit extends Cubit<CreateTripDialogState> {
  /// Constructor for [CreateTripDialogCubit].
  CreateTripDialogCubit({required RouteRepository routeRepository})
      : _routeRepository = routeRepository,
        super(const CreateTripDialogState());

  final RouteRepository _routeRepository;

  /// Loads the routes associated with the current driver.
  Future<void> loadRoutes() async {
    emit(state.copyWith(loadingRoutes: true, clearError: true));
    final result = await _routeRepository.getMyDriverRoutes();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          failure: failure,
        ),
      ),
      (routes) => emit(
        state.copyWith(
          routes: routes,
          selectedRoute: routes.isNotEmpty ? routes.first : null,
        ),
      ),
    );
  }

  /// Updates the selected route in the state.
  void selectRoute(Route? route) {
    emit(state.copyWith(selectedRoute: route));
  }

  /// Updates the scheduled date/time in the state.
  void updateScheduledAt(DateTime dateTime) {
    emit(
      state.copyWith(
        scheduledAt: dateTime,
        clearError: true,
      ),
    );
  }

  /// Sets the submission loading state.
  void setSubmitting({required bool isSubmitting}) {
    emit(
      state.copyWith(
        isSubmitting: isSubmitting,
        clearError: true,
      ),
    );
  }

  /// Sets or clears the failure in the state.
  void setError(Failure? failure) {
    emit(
      state.copyWith(
        failure: failure,
      ),
    );
  }
}

/// State for the [CreateTripDialogCubit].
class CreateTripDialogState {
  /// Constructor for [CreateTripDialogState].
  const CreateTripDialogState({
    this.routes = const [],
    this.selectedRoute,
    this.scheduledAt,
    this.isSubmitting = false,
    this.loadingRoutes = true,
    this.failure,
  });

  /// The list of available routes.
  final List<Route> routes;

  /// The currently selected route for the trip.
  final Route? selectedRoute;

  /// The scheduled date and time for the trip.
  final DateTime? scheduledAt;

  /// Whether the trip is currently being submitted to the server.
  final bool isSubmitting;

  /// Whether the routes are currently loading.
  final bool loadingRoutes;

  /// The failure if any occurred during the process.
  final Failure? failure;

  /// Creates a copy of the state with modified fields.
  CreateTripDialogState copyWith({
    List<Route>? routes,
    Route? selectedRoute,
    bool clearSelectedRoute = false,
    DateTime? scheduledAt,
    bool isSubmitting = false,
    bool loadingRoutes = false,
    Failure? failure,
    bool clearError = false,
  }) {
    return CreateTripDialogState(
      routes: routes ?? this.routes,
      selectedRoute:
          clearSelectedRoute ? null : (selectedRoute ?? this.selectedRoute),
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isSubmitting: isSubmitting,
      loadingRoutes: loadingRoutes,
      failure: clearError ? null : (failure ?? this.failure),
    );
  }
}
