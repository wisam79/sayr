import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part 'create_trip_dialog_cubit.freezed.dart';

/// Manages the state of the create-trip dialog (form).
class CreateTripDialogCubit extends Cubit<CreateTripDialogState> {
  /// Constructor for [CreateTripDialogCubit].
  CreateTripDialogCubit({
    required RouteRepository routeRepository,
    required TripRepository tripRepository,
  })  : _routeRepository = routeRepository,
        _tripRepository = tripRepository,
        super(const CreateTripDialogState());

  final RouteRepository _routeRepository;
  final TripRepository _tripRepository;

  /// Loads the routes associated with the current driver.
  Future<void> loadRoutes() async {
    emit(state.copyWith(loadingRoutes: true, failure: null));
    final result = await _routeRepository.getMyDriverRoutes();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          failure: failure,
          loadingRoutes: false,
        ),
      ),
      (routes) => emit(
        state.copyWith(
          routes: routes,
          selectedRoute: routes.isNotEmpty ? routes.first : null,
          loadingRoutes: false,
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
        failure: null,
      ),
    );
  }

  /// Sets or clears the failure in the state.
  void setError(Failure? failure) {
    emit(
      state.copyWith(
        failure: failure,
        isSubmitting: false,
      ),
    );
  }

  /// Creates the trip using the repository.
  Future<Trip?> createTrip() async {
    final route = state.selectedRoute;
    if (route == null) return null;

    final scheduledAt =
        state.scheduledAt ?? DateTime.now().add(const Duration(minutes: 10));

    if (!scheduledAt.isAfter(DateTime.now())) {
      setError(const ValidationFailure(message: 'trip_time_must_be_future'));
      return null;
    }

    emit(state.copyWith(isSubmitting: true, failure: null));

    final result = await _tripRepository.createTrip(
      routeId: route.id,
      scheduledAt: scheduledAt,
    );

    if (isClosed) return null;

    return result.fold(
      (failure) {
        setError(failure);
        return null;
      },
      (trip) {
        emit(state.copyWith(isSubmitting: false));
        return trip;
      },
    );
  }
}

/// State for the [CreateTripDialogCubit].
@freezed
abstract class CreateTripDialogState with _$CreateTripDialogState {
  /// Constructor for [CreateTripDialogState].
  const factory CreateTripDialogState({
    /// The list of available routes.
    @Default([]) List<Route> routes,

    /// The currently selected route for the trip.
    Route? selectedRoute,

    /// The scheduled date and time for the trip.
    DateTime? scheduledAt,

    /// Whether the trip is currently being submitted to the server.
    @Default(false) bool isSubmitting,

    /// Whether the routes are currently loading.
    @Default(true) bool loadingRoutes,

    /// The failure if any occurred during the process.
    Failure? failure,
  }) = _CreateTripDialogState;
}
