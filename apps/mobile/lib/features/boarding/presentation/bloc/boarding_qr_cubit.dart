import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// State for the student QR boarding page.
sealed class BoardingQrState {
  const BoardingQrState();
}

class BoardingQrInitial extends BoardingQrState {
  const BoardingQrInitial();
}

class BoardingQrLoading extends BoardingQrState {
  const BoardingQrLoading();
}

/// No active trip is in a boardable state for any of the student's
/// subscribed routes.
class BoardingQrNoActiveTrip extends BoardingQrState {
  const BoardingQrNoActiveTrip();
}

class BoardingQrReady extends BoardingQrState {
  const BoardingQrReady({
    required this.tripId,
    required this.token,
    required this.expiresAt,
    required this.secondsUntilRefresh,
    this.proximityOtp,
    this.isSubmittingProximity = false,
    this.proximityRecord,
    this.refreshFailure,
    this.proximityFailure,
  });

  final TripId tripId;
  final String token;
  final DateTime expiresAt;
  final int secondsUntilRefresh;
  final String? proximityOtp;
  final bool isSubmittingProximity;
  final BoardingRecord? proximityRecord;
  final Failure? refreshFailure;
  final Failure? proximityFailure;

  BoardingQrReady copyWith({
    TripId? tripId,
    String? token,
    DateTime? expiresAt,
    int? secondsUntilRefresh,
    String? proximityOtp,
    bool? isSubmittingProximity,
    BoardingRecord? proximityRecord,
    bool clearProximityOtp = false,
    Failure? refreshFailure,
    bool clearRefreshFailure = false,
    Failure? proximityFailure,
    bool clearProximityFailure = false,
  }) {
    return BoardingQrReady(
      tripId: tripId ?? this.tripId,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      secondsUntilRefresh: secondsUntilRefresh ?? this.secondsUntilRefresh,
      proximityOtp:
          clearProximityOtp ? null : (proximityOtp ?? this.proximityOtp),
      isSubmittingProximity:
          isSubmittingProximity ?? this.isSubmittingProximity,
      proximityRecord: proximityRecord ?? this.proximityRecord,
      refreshFailure:
          clearRefreshFailure ? null : (refreshFailure ?? this.refreshFailure),
      proximityFailure: clearProximityFailure
          ? null
          : (proximityFailure ?? this.proximityFailure),
    );
  }
}

class BoardingQrError extends BoardingQrState {
  const BoardingQrError({required this.failure});
  final Failure failure;
}

/// Cubit for the student-side QR boarding page.
///
/// Automatically detects the active trip for the student's subscription,
/// refreshes the QR token every ~25 seconds, and scans for BLE beacons for proximity boarding.
class BoardingQrCubit extends Cubit<BoardingQrState> {
  /// Creates a [BoardingQrCubit].
  BoardingQrCubit({
    required BoardingRepository boardingRepository,
    BleBeaconService? bleBeaconService,
  })  : _boardingRepository = boardingRepository,
        _bleBeaconService = bleBeaconService ?? sl<BleBeaconService>(),
        super(const BoardingQrInitial());

  final BoardingRepository _boardingRepository;
  final BleBeaconService _bleBeaconService;

  StreamSubscription<int>? _timerSubscription;
  StreamSubscription<({TripId tripId, String otp})>? _bleSubscription;
  TripId? _activeTripId;
  DateTime? _currentExpiresAt;
  DateTime? _lastRefreshTime;

  /// Begin watching for active trips, generating tokens, and scanning BLE beacons.
  Future<void> start() async {
    emit(const BoardingQrLoading());
    final result = await _boardingRepository.getActiveTripForSubscription();
    if (isClosed) return;
    await result.fold(
      (failure) async {
        emit(BoardingQrError(failure: failure));
      },
      (tripId) async {
        if (tripId == null) {
          emit(const BoardingQrNoActiveTrip());
          return;
        }
        _activeTripId = tripId;
        await _refreshToken();
        await _startBleScanning();
      },
    );
  }

  Future<void> _startBleScanning() async {
    unawaited(_bleSubscription?.cancel());

    final started = await _bleBeaconService.startScanning();
    if (isClosed) return;
    if (!started) {
      sl<Talker>().warning(
        'BLE scanning not started. Student will use QR code boarding.',
      );
      return;
    }
    _bleSubscription = _bleBeaconService.discoveredTrips.listen((data) {
      final current = state;
      if (current is BoardingQrReady) {
        if (data.tripId == current.tripId) {
          emit(current.copyWith(proximityOtp: data.otp));
        }
      }
    });
  }

  /// Submit check-in via BLE proximity.
  Future<void> submitProximityCheckIn(Coordinates? location) async {
    final current = state;
    if (current is! BoardingQrReady || current.proximityOtp == null) return;

    emit(current.copyWith(
        isSubmittingProximity: true, clearProximityFailure: true));

    final result = await _boardingRepository.validateBoardingViaProximity(
      tripId: current.tripId,
      otp: current.proximityOtp!,
      studentLocation: location,
    );

    if (isClosed) return;
    final latestState = state;
    if (latestState is! BoardingQrReady) return;

    result.fold(
      (failure) {
        emit(
          latestState.copyWith(
            isSubmittingProximity: false,
            proximityFailure: failure,
          ),
        );
      },
      (record) {
        emit(
          latestState.copyWith(
            isSubmittingProximity: false,
            proximityRecord: record,
          ),
        );
      },
    );
  }

  Future<void> _refreshToken() async {
    final tripId = _activeTripId;
    if (tripId == null) {
      return;
    }
    _lastRefreshTime = DateTime.now();
    final result = await _boardingRepository.generateBoardingToken(tripId);
    if (isClosed) return;
    result.fold(
      (failure) {
        final current = state;
        if (current is BoardingQrReady) {
          emit(current.copyWith(refreshFailure: failure));
        } else {
          _timerSubscription?.cancel();
          _timerSubscription = null;
          emit(BoardingQrError(failure: failure));
        }
      },
      (tokenResult) {
        _currentExpiresAt = tokenResult.expiresAt;
        final current = state;
        if (current is BoardingQrReady) {
          emit(
            current.copyWith(
              token: tokenResult.token,
              expiresAt: tokenResult.expiresAt,
              secondsUntilRefresh: tokenResult.expiresAt
                  .difference(DateTime.now())
                  .inSeconds
                  .clamp(0, 60),
              clearRefreshFailure: true,
            ),
          );
        } else {
          emit(
            BoardingQrReady(
              tripId: tripId,
              token: tokenResult.token,
              expiresAt: tokenResult.expiresAt,
              secondsUntilRefresh: tokenResult.expiresAt
                  .difference(DateTime.now())
                  .inSeconds
                  .clamp(0, 60),
            ),
          );
        }
        _startTimer();
      },
    );
  }

  void _startTimer() {
    if (_timerSubscription != null) return;
    _timerSubscription =
        Stream.periodic(const Duration(seconds: 1), (tick) => tick).listen((_) {
      final expires = _currentExpiresAt;
      final current = state;
      if (expires == null || current is! BoardingQrReady) return;

      final now = DateTime.now();
      final remaining = expires.difference(now).inSeconds.clamp(0, 60);
      if (remaining != current.secondsUntilRefresh) {
        emit(current.copyWith(secondsUntilRefresh: remaining));
      }

      final lastRefresh = _lastRefreshTime;
      final hasError = current.refreshFailure != null;
      final retryInterval = hasError ? 5 : 25;
      if (lastRefresh == null ||
          now.difference(lastRefresh).inSeconds >= retryInterval) {
        _refreshToken();
      }
    });
  }

  @override
  Future<void> close() async {
    await _timerSubscription?.cancel();
    await _bleSubscription?.cancel();
    await _bleBeaconService.stopScanning();
    return super.close();
  }
}
