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
  StreamSubscription<void>? _mockSubscription;
  StreamSubscription<int>? _otpSubscription;
  bool _isMockMode = false;

  /// Prefix used in local name advertisement.
  static const String localNamePrefix = 'SAYR_';

  /// Stream of discovered trips with their current OTP.
  Stream<({TripId tripId, String otp})> get discoveredTrips =>
      _discoveredTripsController.stream;

  /// Starts BLE advertising for the given trip and OTP.
  /// Starts BLE advertising for the given trip and OTP.
  Future<void> startAdvertising({
    required TripId tripId,
    required String otp,
  }) async {
    _logger
        .d('Starting BLE Advertising for TripId=${tripId.value} with OTP=$otp');
    _isMockMode = false;
    try {
      final isSupported = await _blePeripheral.isSupported;
      if (!isSupported) {
        _logger.w(
          'BLE Peripheral is not supported on this device. Falling back to mock.',
        );
        _isMockMode = true;
        _startMockAdvertising(tripId, otp);
        return;
      }

      final advertiseData = AdvertiseData(
        serviceUuid: tripId.value,
        localName: '$localNamePrefix$otp',
        includeDeviceName: true,
      );

      await _blePeripheral.start(advertiseData: advertiseData);
      _logger.d('BLE Advertising started successfully');
    } catch (e, st) {
      _logger.e(
        'Failed to start BLE advertising, falling back to mock',
        error: e,
        stackTrace: st,
      );
      _isMockMode = true;
      _startMockAdvertising(tripId, otp);
    }
  }

  /// Stops BLE advertising.
  Future<void> stopAdvertising() async {
    await _mockSubscription?.cancel();
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
    _logger.d('Starting BLE scanning for Sayr Beacons');
    _isMockMode = false;
    try {
      final isAvailable = await FlutterBluePlus.isSupported;
      if (!isAvailable) {
        _logger.w(
          'Bluetooth is not supported on this device. Using mock scanning.',
        );
        _isMockMode = true;
        _startMockScanning();
        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _logger.w(
          'Bluetooth adapter is off (state: $adapterState). Using mock scanning.',
        );
        _isMockMode = true;
        _startMockScanning();
        return false;
      }

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final r in results) {
            final localName = r.advertisementData.advName;
            if (localName.startsWith(localNamePrefix)) {
              final otp = localName.substring(localNamePrefix.length);
              final serviceUuids = r.advertisementData.serviceUuids;
              if (serviceUuids.isNotEmpty) {
                final tripIdStr = serviceUuids.first.toString();
                _discoveredTripsController.add(
                  (
                    tripId: TripId(tripIdStr),
                    otp: otp,
                  ),
                );
              }
            }
          }
        },
        onError: (Object e, StackTrace st) {
          _logger.e('Error during BLE scan stream', error: e, stackTrace: st);
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(minutes: 10),
        androidUsesFineLocation: true,
      );
      _logger.d('Real BLE scanning started successfully');
      return true;
    } catch (e, st) {
      _logger.e(
        'Failed to start real BLE scan, falling back to mock',
        error: e,
        stackTrace: st,
      );
      _isMockMode = true;
      _startMockScanning();
      return false;
    }
  }

  /// Stops BLE scanning.
  Future<void> stopScanning() async {
    await _mockSubscription?.cancel();
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
    _mockSubscription?.cancel();
    if (!kDebugMode) {
      _logger.d('Mock advertising is disabled in non-debug mode.');
      return;
    }
    _logger.d('Mock BLE Advertising: TripId=${tripId.value} OTP=$otp');
  }

  void _startMockScanning() {
    _mockSubscription?.cancel();
    if (!kDebugMode) {
      _logger.d('Mock scanning is disabled in non-debug mode.');
      return;
    }
    _logger
        .d('Mock BLE scanning started. Will emit a fake trip in 3 seconds...');
    _mockSubscription = Stream<void>.fromFuture(
      Future<void>.delayed(const Duration(seconds: 3)),
    ).listen((_) {
      _discoveredTripsController.add(
        (
          tripId: const TripId('mock-trip-id-12345'),
          otp: 'MOCK12',
        ),
      );
      _logger.d('Mock BLE scan result emitted');
    });
  }

  /// Starts rotating BLE advertising for the given trip.
  /// Automatically generates OTP, updates database via [tripRepository], and advertises.
  void startRotatingOtpAdvertising({
    required TripId tripId,
    required TripRepository tripRepository,
    required Logger logger,
  }) {
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
    _otpSubscription = Stream<int>.periodic(const Duration(seconds: 30), (x) => x)
        .listen((_) => updateOtp());
  }

  /// Stops rotating BLE advertising.
  void stopRotatingOtpAdvertising() {
    unawaited(_otpSubscription?.cancel());
    _otpSubscription = null;
    stopAdvertising();
  }
}
