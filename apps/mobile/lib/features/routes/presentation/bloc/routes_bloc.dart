import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_data/sayr_data.dart';

import 'routes_event.dart';
import 'routes_state.dart';

/// Bloc for fetching and managing routes.
class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  RoutesBloc({required RouteRepository routeRepository})
      : _routeRepository = routeRepository,
        super(const RoutesInitial()) {
    on<RoutesLoadRequested>(_onLoadRequested);
    on<RoutesSearchRequested>(_onSearchRequested);
  }

  final RouteRepository _routeRepository;

  Future<void> _onLoadRequested(
    RoutesLoadRequested event,
    Emitter<RoutesState> emit,
  ) async {
    emit(const RoutesLoading());

    final result = await _routeRepository.getActiveRoutes();

    result.fold(
      (failure) => emit(RoutesError(failure)),
      (routes) => emit(RoutesLoaded(routes)),
    );
  }

  Future<void> _onSearchRequested(
    RoutesSearchRequested event,
    Emitter<RoutesState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      add(const RoutesLoadRequested());
      return;
    }

    emit(const RoutesLoading());

    final result = await _routeRepository.search(event.query.trim());

    result.fold(
      (failure) => emit(RoutesError(failure)),
      (routes) => emit(RoutesLoaded(routes)),
    );
  }
}
