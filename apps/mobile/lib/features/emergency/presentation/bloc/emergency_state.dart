import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart'
    show EmergencyBloc;

part 'emergency_state.freezed.dart';

/// State for [EmergencyBloc].
@freezed
sealed class EmergencyState with _$EmergencyState {
  /// No SOS has been sent, or the previous one was resolved.
  const factory EmergencyState.idle() = EmergencyIdle;

  /// An SOS is being sent to the server.
  const factory EmergencyState.sending() = EmergencySending;

  /// An active emergency report exists.
  const factory EmergencyState.active({
    required EmergencyReport report,
  }) = EmergencyActive;

  /// The last operation failed.
  const factory EmergencyState.failed({
    required Failure failure,
    EmergencyReport? activeReport,
  }) = EmergencyFailed;
}
