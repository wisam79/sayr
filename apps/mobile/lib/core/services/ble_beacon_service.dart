import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sayr_core/sayr_core.dart';

/// Service to handle BLE-based proximity boarding.
///
/// In driver mode: Advertises the [TripId] as the primary Service UUID and the rotating OTP as the device's local name.
/// In student mode: Scans for nearby BLE peripherals with local names matching "SAYR_OTP".
@lazySingleton
class BleBeaconService {
  /// Creates a [BleBeaconService].
  BleBeaconService() : _blePeripheral = FlutterBlePeripheral();

  final FlutterBlePeripheral _blePeripheral;
  final Logger _logger = Logger();
  final _discoveredTripsController =
      StreamController<({TripId tripId, String otp})>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _mockTimer;
  Timer? _otpTimer;
  bool _isMockMode = false;

  /// Prefix used in local name advertisement.
  static const String localNamePrefix = 'SAYR_';

  /// Stream of discovered trips with their current OTP.
  Stream<({TripId tripId, String otp})> get discoveredTrips =>
      _discoveredTripsController.stream;

  /// Starts BLE advertising for the given trip and OTP.
  Future<void> startAdvertising({
    required TripId tripId,
    required String otp,
  }) async {
    _logger.w(
        'BLE advertising is temporarily disabled for security reasons (Vulnerability #2)');
    _isMockMode = true;
    _startMockAdvertising(tripId, otp);
  }

  /// Stops BLE advertising.
  Future<void> stopAdvertising() async {
    _mockTimer?.cancel();
    if (_isMockMode) return;
    try {
      await _blePeripheral.stop();
      _logger.d('BLE Advertising stopped');
    } catch (e, st) {
      _logger.d(
        'BLE stopAdvertising threw (peripheral may already be stopped)',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Starts scanning for nearby Sayr Beacons.
  Future<bool> startScanning() async {
    _logger.w(
        'BLE scanning is temporarily disabled for security reasons (Vulnerability #2)');
    _isMockMode = true;
    _startMockScanning();
    return false;
  }

  /// Stops BLE scanning.
  Future<void> stopScanning() async {
    _mockTimer?.cancel();
    await _scanSubscription?.cancel();
    if (_isMockMode) return;
    try {
      await FlutterBluePlus.stopScan();
      _logger.d('BLE Scanning stopped');
    } catch (e, st) {
      _logger.d(
        'BLE stopScan threw (scanner may already be stopped)',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _startMockAdvertising(TripId tripId, String otp) {
    _mockTimer?.cancel();
    if (!kDebugMode) {
      _logger.d('Mock advertising is disabled in non-debug mode.');
      return;
    }
    _logger.d('Mock BLE Advertising: TripId=${tripId.value}');
  }

  void _startMockScanning() {
    _mockTimer?.cancel();
    if (!kDebugMode) {
      _logger.d('Mock scanning is disabled in non-debug mode.');
      return;
    }
    _logger.d('Mock BLE scanning started (no proximity data broadcast).');
  }

  /// Starts rotating BLE advertising for the given trip.
  /// Automatically generates OTP, updates database via [tripRepository], and advertises.
  void startRotatingOtpAdvertising({
    required TripId tripId,
    required TripRepository tripRepository,
    required Logger logger,
  }) {
    _otpTimer?.cancel();

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
        final expiresAt = DateTime.now().add(const Duration(seconds: 45));

        final result = await tripRepository.updateBleOtp(
          tripId: tripId,
          otp: otp,
          expiresAt: expiresAt,
        );

        await result.fold(
          (failure) async {
            logger.e('Failed to update BLE OTP in repository: $failure');
          },
          (_) async {
            await startAdvertising(tripId: tripId, otp: otp);
          },
        );
      } catch (e, st) {
        logger.e(
          'Failed to rotate BLE OTP in periodic timer',
          error: e,
          stackTrace: st,
        );
      }
    }

    updateOtp();
    _otpTimer = Timer.periodic(const Duration(seconds: 30), (_) => updateOtp());
  }

  /// Stops rotating BLE advertising.
  void stopRotatingOtpAdvertising() {
    _otpTimer?.cancel();
    _otpTimer = null;
    stopAdvertising();
  }
}
