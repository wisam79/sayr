import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_state.dart';

part 'emergency_event.dart';

/// BLoC for the SOS / emergency flow.
class EmergencyBloc extends Bloc<EmergencyEvent, EmergencyState> {
  /// Creates an [EmergencyBloc] with the given [emergencyRepository].
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

    final result = await _repository.triggerEmergency(
      tripId: event.tripId,
      routeId: event.routeId,
      location: event.location,
      message: event.message,
    );

    if (isClosed) return;
    result.fold(
      (Failure failure) => emit(EmergencyState.failed(failure: failure)),
      (EmergencyReport report) => emit(EmergencyState.active(report: report)),
    );
  }

  Future<void> _onCancelled(
    EmergencyCancelled event,
    Emitter<EmergencyState> emit,
  ) async {
    final stateSnapshot = state;
    final EmergencyReport? report;
    if (stateSnapshot is EmergencyActive) {
      report = stateSnapshot.report;
    } else if (stateSnapshot is EmergencyFailed &&
        stateSnapshot.activeReport != null) {
      report = stateSnapshot.activeReport;
    } else {
      return;
    }

    emit(const EmergencyState.sending());
    final result = await _repository.resolveReport(report!.id);

    if (isClosed) return;
    result.fold(
      (Failure failure) => emit(
        EmergencyState.failed(
          failure: failure,
          activeReport: report,
        ),
      ),
      (Unit _) => emit(const EmergencyState.idle()),
    );
  }

  void _onReset(EmergencyReset event, Emitter<EmergencyState> emit) {
    emit(const EmergencyState.idle());
  }
}
