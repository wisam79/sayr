import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/routes/presentation/bloc/routes_event.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_state.dart';

/// Bloc for fetching and managing routes.
class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  /// Creates a [RoutesBloc] with the given [routeRepository].
  RoutesBloc({required RouteRepository routeRepository})
      : _routeRepository = routeRepository,
        super(const RoutesInitial()) {
    on<RoutesLoadRequested>(_onLoadRequested);
    on<RoutesSearchRequested>(
      _onSearchRequested,
      transformer: (events, mapper) => restartable<RoutesSearchRequested>()(
        events.debounce(const Duration(milliseconds: 400)),
        mapper,
      ),
    );
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
