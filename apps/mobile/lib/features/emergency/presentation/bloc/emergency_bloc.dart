import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';

import 'emergency_state.dart';

part 'emergency_event.dart';

/// BLoC for the SOS / emergency flow.
class EmergencyBloc extends Bloc<EmergencyEvent, EmergencyState> {
  EmergencyBloc({required EmergencyRepository emergencyRepository})
      : _repository = emergencyRepository,
        super(const EmergencyState.idle()) {
    on<EmergencyTriggered>(_onTriggered);
    on<EmergencyCancelled>(_onCancelled);
    on<EmergencyReset>(_onReset);
  }

  final EmergencyRepository _repository;

  Future<void> _onTriggered(
    EmergencyTriggered event,
    Emitter<EmergencyState> emit,
  ) async {
    emit(const EmergencyState.sending());

    final Either<Failure, EmergencyReport> result =
        await _repository.triggerEmergency(
      tripId: event.tripId,
      routeId: event.routeId,
      location: event.location,
      message: event.message,
    );

    result.fold(
      (Failure failure) => emit(EmergencyState.failed(failure: failure)),
      (EmergencyReport report) => emit(EmergencyState.active(report: report)),
    );
  }

  Future<void> _onCancelled(
    EmergencyCancelled event,
    Emitter<EmergencyState> emit,
  ) async {
    final EmergencyState stateSnapshot = state;
    if (stateSnapshot is! EmergencyActive) return;

    emit(const EmergencyState.sending());
    final Either<Failure, Unit> result =
        await _repository.resolveReport(stateSnapshot.report.id);

    result.fold(
      (Failure failure) => emit(EmergencyState.failed(failure: failure)),
      (Unit _) => emit(const EmergencyState.idle()),
    );
  }

  void _onReset(EmergencyReset event, Emitter<EmergencyState> emit) {
    emit(const EmergencyState.idle());
  }
}
