import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/core/services/ble_beacon_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'ble_otp_cubit.freezed.dart';

/// States for BLE OTP rotation.
@freezed
sealed class BleOtpState with _$BleOtpState {
  /// Initial state when rotation hasn't started.
  const factory BleOtpState.initial() = BleOtpInitial;

  /// State when OTP is successfully rotating.
  const factory BleOtpState.rotating({
    required String otp,
    required DateTime expiresAt,
  }) = BleOtpRotating;

  /// State when OTP rotation fails.
  const factory BleOtpState.failure(Failure failure) = BleOtpFailure;

  /// State when OTP rotation stops.
  const factory BleOtpState.stopped() = BleOtpStopped;
}

/// Cubit responsible for generating, rotating, updating repository, and advertising BLE OTP.
class BleOtpCubit extends Cubit<BleOtpState> {
  /// Creates a [BleOtpCubit] with the given services and repositories.
  BleOtpCubit({
    required BleBeaconService bleBeaconService,
    required TripRepository tripRepository,
    required Talker talker,
  })  : _bleBeaconService = bleBeaconService,
        _tripRepository = tripRepository,
        _talker = talker,
        super(const BleOtpState.initial());

  final BleBeaconService _bleBeaconService;
  final TripRepository _tripRepository;
  final Talker _talker;

  StreamSubscription<int>? _otpSubscription;

  /// Starts rotating BLE advertising for the given trip.
  void startRotatingOtp(TripId tripId) {
    _otpSubscription?.cancel();

    String generateOtp() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rnd = Random.secure();
      return String.fromCharCodes(
        Iterable.generate(
          6,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
        ),
      );
    }

    Future<void> updateOtp() async {
      try {
        final otp = generateOtp();
        // Expiry is set to 60 s (rotation is every 30 s).
        // The 30 s buffer absorbs typical RPC latency so the server always
        // stores an OTP that is valid for at least 30 s from server receipt.
        final expiresAt = DateTime.now().add(const Duration(seconds: 60));

        emit(BleOtpState.rotating(otp: otp, expiresAt: expiresAt));

        // Call repository to save OTP remotely.
        final result = await _tripRepository.updateBleOtp(
          tripId: tripId,
          otp: otp,
          expiresAt: expiresAt,
        );

        // If repository update fails, we still advertise the OTP locally (Offline Resilience)
        // so students next to the bus can scan it.
        await result.fold(
          (failure) async {
            _talker.warning(
              'Failed to update BLE OTP in repository. Advertising locally anyway: $failure',
            );
            await _bleBeaconService.startAdvertising(tripId: tripId, otp: otp);
          },
          (_) async {
            await _bleBeaconService.startAdvertising(tripId: tripId, otp: otp);
          },
        );
      } catch (e, st) {
        _talker.error(
          'Failed to rotate BLE OTP in periodic timer',
          e,
          st,
        );
        emit(BleOtpState.failure(UnknownFailure(message: e.toString())));
      }
    }

    updateOtp();
    _otpSubscription =
        Stream<int>.periodic(const Duration(seconds: 30), (x) => x)
            .listen((_) => updateOtp());
  }

  /// Stops rotating BLE advertising.
  void stopRotatingOtp() {
    _otpSubscription?.cancel();
    _otpSubscription = null;
    _bleBeaconService.stopAdvertising();
    emit(const BleOtpState.stopped());
  }

  @override
  Future<void> close() {
    _otpSubscription?.cancel();
    return super.close();
  }
}
