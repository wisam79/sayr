import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';

/// State for the driver-side boarding scanner.
sealed class BoardingScannerState {
  const BoardingScannerState();
}

class BoardingScannerInitial extends BoardingScannerState {
  const BoardingScannerInitial();
}

class BoardingScannerReady extends BoardingScannerState {
  const BoardingScannerReady({
    required this.tripId,
    required this.passengers,
    this.lastScan,
    this.isProcessing = false,
  });
  final TripId tripId;
  final List<BoardingRecord> passengers;
  final BoardingScanResult? lastScan;
  final bool isProcessing;
}

class BoardingScannerError extends BoardingScannerState {
  const BoardingScannerError({required this.failure});
  final Failure failure;
}

/// Result of a single QR scan attempt.
sealed class BoardingScanResult {
  const BoardingScanResult();
}

class BoardingScanSuccess extends BoardingScanResult {
  const BoardingScanSuccess({required this.record});
  final BoardingRecord record;
}

class BoardingScanFailure extends BoardingScanResult {
  const BoardingScanFailure({required this.failure});
  final Failure failure;
}

/// Cubit for the driver-side boarding scanner.
///
/// Subscribes to the realtime passenger list for a trip and processes
/// scanned QR tokens via [processToken].
class BoardingScannerCubit extends Cubit<BoardingScannerState> {
  /// Creates a [BoardingScannerCubit].
  BoardingScannerCubit({
    required BoardingRepository boardingRepository,
    required TripId tripId,
  })  : _boardingRepository = boardingRepository,
        _tripId = tripId,
        super(const BoardingScannerInitial());

  final BoardingRepository _boardingRepository;
  final TripId _tripId;
  StreamSubscription<List<BoardingRecord>>? _passengerSub;

  /// Begin watching the trip's passenger list.
  void start() {
    _passengerSub?.cancel();
    _passengerSub = _boardingRepository.watchTripPassengers(_tripId).listen(
      (passengers) {
        final current = state;
        emit(
          BoardingScannerReady(
            tripId: _tripId,
            passengers: passengers,
            lastScan: current is BoardingScannerReady ? current.lastScan : null,
            isProcessing:
                current is BoardingScannerReady && current.isProcessing,
          ),
        );
      },
      onError: (Object error) {
        emit(BoardingScannerError(
            failure: UnknownFailure(message: error.toString())));
      },
    );
  }

  /// Process a QR token scanned by the driver.
  Future<void> processToken(String token, {Coordinates? driverLocation}) async {
    final current = state;
    if (current is! BoardingScannerReady || current.isProcessing) return;

    emit(
      BoardingScannerReady(
        tripId: _tripId,
        passengers: current.passengers,
        isProcessing: true,
      ),
    );

    final result = await _boardingRepository.validateBoarding(
      token: token,
      tripId: _tripId,
      driverLocation: driverLocation,
    );

    if (isClosed) return;

    // Small delay to allow the scanner debounce/feedback to show
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (isClosed) return;

    final updated = state;
    final passengers = updated is BoardingScannerReady
        ? updated.passengers
        : current.passengers;

    result.fold(
      (failure) {
        emit(
          BoardingScannerReady(
            tripId: _tripId,
            passengers: passengers,
            lastScan: BoardingScanFailure(
              failure: failure,
            ),
          ),
        );
      },
      (record) {
        emit(
          BoardingScannerReady(
            tripId: _tripId,
            passengers: passengers,
            lastScan: BoardingScanSuccess(record: record),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _passengerSub?.cancel();
    return super.close();
  }
}
