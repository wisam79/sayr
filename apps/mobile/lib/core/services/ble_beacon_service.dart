import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Service to handle BLE-based proximity boarding.
///
/// In driver mode: Advertises the [TripId] as the primary Service UUID and the rotating OTP as the device's local name.
/// In student mode: Scans for nearby BLE peripherals with local names matching "SAYR_OTP".
@lazySingleton
class BleBeaconService {
  /// Creates a [BleBeaconService].
  BleBeaconService(Talker talker)
      : _blePeripheral = FlutterBlePeripheral(),
        _talker = talker;

  final FlutterBlePeripheral _blePeripheral;
  final Talker _talker;
  final _discoveredTripsController =
      StreamController<({TripId tripId, String otp})>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<void>? _mockSubscription;
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
    _talker.debug('Starting BLE Advertising for TripId=${tripId.value} with OTP=$otp');
    _isMockMode = false;
    try {
      final isSupported = await _blePeripheral.isSupported;
      if (!isSupported) {
        _talker.warning(
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
      _talker.debug('BLE Advertising started successfully');
    } catch (e, st) {
      _talker.error(
        'Failed to start BLE advertising, falling back to mock',
        e,
        st,
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
      _talker.debug('BLE Advertising stopped');
    } catch (e, st) {
      _talker.debug(
        'BLE stopAdvertising threw (peripheral may already be stopped)',
        e,
        st,
      );
    }
  }

  /// Starts scanning for nearby Sayr Beacons.
  Future<bool> startScanning() async {
    _talker.debug('Starting BLE scanning for Sayr Beacons');
    _isMockMode = false;
    try {
      final isAvailable = await FlutterBluePlus.isSupported;
      if (!isAvailable) {
        _talker.warning(
          'Bluetooth is not supported on this device. Using mock scanning.',
        );
        _isMockMode = true;
        _startMockScanning();
        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => BluetoothAdapterState.unknown,
      );
      if (adapterState != BluetoothAdapterState.on) {
        _talker.warning(
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
          _talker.error('Error during BLE scan stream', e, st);
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(minutes: 10),
        androidUsesFineLocation: true,
      );
      _talker.debug('Real BLE scanning started successfully');
      return true;
    } catch (e, st) {
      _talker.error(
        'Failed to start real BLE scan, falling back to mock',
        e,
        st,
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
      _talker.debug('BLE Scanning stopped');
    } catch (e, st) {
      _talker.debug(
        'BLE stopScan threw (scanner may already be stopped)',
        e,
        st,
      );
    }
  }

  void _startMockAdvertising(TripId tripId, String otp) {
    _mockSubscription?.cancel();
    if (!kDebugMode) {
      _talker.debug('Mock advertising is disabled in non-debug mode.');
      return;
    }
    _talker.debug('Mock BLE Advertising: TripId=${tripId.value} OTP=$otp');
  }

  void _startMockScanning() {
    _mockSubscription?.cancel();
    if (!kDebugMode) {
      _talker.debug('Mock scanning is disabled in non-debug mode.');
      return;
    }
    _talker.debug('Mock BLE scanning started. Will emit a fake trip in 3 seconds...');
    _mockSubscription = Stream<void>.fromFuture(
      Future<void>.delayed(const Duration(seconds: 3)),
    ).listen((_) {
      _discoveredTripsController.add(
        (
          tripId: const TripId('mock-trip-id-12345'),
          otp: 'MOCK12',
        ),
      );
      _talker.debug('Mock BLE scan result emitted');
    });
  }

  /// Closes streams and subscriptions to prevent memory leaks.
  @disposeMethod
  void dispose() {
    _discoveredTripsController.close();
    _scanSubscription?.cancel();
    _mockSubscription?.cancel();
  }
}
