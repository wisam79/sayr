import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
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
    try {
      final isSupported = await _blePeripheral.isSupported;
      if (!isSupported) {
        if (!kDebugMode) {
          throw UnsupportedError('BLE not supported on this device');
        }
        _isMockMode = true;
        _startMockAdvertising(tripId, otp);
        return;
      }

      final data = AdvertiseData(
        serviceUuid: tripId.value,
        localName: '$localNamePrefix$otp',
      );

      await _blePeripheral.start(advertiseData: data);
      _isMockMode = false;
      debugPrint(
        'BLE Advertising started for TripId: ${tripId.value}, OTP: $otp',
      );
    } catch (e) {
      debugPrint('BLE Advertising error: $e');
      if (!kDebugMode) {
        _logger.e('BLE Advertising failed: $e');
        rethrow;
      }
      _isMockMode = true;
      _startMockAdvertising(tripId, otp);
    }
  }

  /// Stops BLE advertising.
  Future<void> stopAdvertising() async {
    _mockTimer?.cancel();
    if (_isMockMode) return;
    try {
      await _blePeripheral.stop();
      debugPrint('BLE Advertising stopped');
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
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        if (!kDebugMode) {
          throw UnsupportedError('BLE not supported on this device');
        }
        _isMockMode = true;
        _startMockScanning();
        return true;
      }

      // Check if Bluetooth is turned on
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        debugPrint('Bluetooth is not ON (state: $state). Cannot scan.');
        return false;
      }

      await FlutterBluePlus.startScan(
        timeout: const Duration(minutes: 5),
        androidUsesFineLocation: true,
      );

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final localName = r.advertisementData.advName;
          if (localName.startsWith(localNamePrefix) &&
              localName.length == (localNamePrefix.length + 6)) {
            final otp = localName.substring(localNamePrefix.length);
            final serviceUuids = r.advertisementData.serviceUuids;
            if (serviceUuids.isNotEmpty) {
              final tripIdStr = serviceUuids.first.toString();
              try {
                final tripId = TripId(tripIdStr);
                _discoveredTripsController.add((tripId: tripId, otp: otp));
              } catch (e, st) {
                _logger.d(
                  'Skipping malformed TripId in BLE advertisement: '
                  '"$tripIdStr"',
                  error: e,
                  stackTrace: st,
                );
              }
            }
          }
        }
      });
      _isMockMode = false;
      debugPrint('BLE Scanning started');
      return true;
    } catch (e) {
      debugPrint('BLE Scanning error: $e');
      if (!kDebugMode) {
        _logger.e('BLE Scanning failed: $e');
        rethrow;
      }
      _isMockMode = true;
      _startMockScanning();
      return true;
    }
  }

  /// Stops BLE scanning.
  Future<void> stopScanning() async {
    _mockTimer?.cancel();
    await _scanSubscription?.cancel();
    if (_isMockMode) return;
    try {
      await FlutterBluePlus.stopScan();
      debugPrint('BLE Scanning stopped');
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
      debugPrint('Mock advertising is disabled in non-debug mode.');
      return;
    }
    debugPrint('Mock BLE Advertising: TripId=${tripId.value}, OTP=$otp');
  }

  void _startMockScanning() {
    _mockTimer?.cancel();
    if (!kDebugMode) {
      debugPrint('Mock scanning is disabled in non-debug mode.');
      return;
    }
    // Simulate discovering a mock trip for development testing
    _mockTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      // Broadcast a mock trip ID and OTP (simulating proximity)
      _discoveredTripsController.add(
        (
          tripId: const TripId('00000000-0000-0000-0000-000000000000'),
          otp: 'MOCK12',
        ),
      );
    });
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
