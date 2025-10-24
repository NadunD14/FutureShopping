import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/positioning_models.dart';
import 'indoor_positioning_service.dart';
import 'mall_data_service.dart';

/// Refactored BLE service for multi-beacon mall navigation
class MallBleService {
  MallBleService._();
  static final instance = MallBleService._();

  final StreamController<Map<String, Beacon>> _beaconsController =
      StreamController<Map<String, Beacon>>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Configuration
  static const String targetServiceUuid =
      'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0';
  static const Duration scanTimeout = Duration(seconds: 5);
  static const int rssiThreshold =
      -100; // More permissive for mall-wide detection
  static const Duration beaconTimeout = Duration(seconds: 10);

  final Map<String, Beacon> _detectedBeacons = {};
  Timer? _scanTimer;
  Timer? _cleanupTimer;
  bool _isScanning = false;

  /// Stream of all detected beacons
  Stream<Map<String, Beacon>> get beaconsStream => _beaconsController.stream;

  /// Get all currently detected beacons
  Map<String, Beacon> get detectedBeacons => Map.from(_detectedBeacons);

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      if (!await _checkPermissions()) {
        print('Permissions not granted');
        return false;
      }

      if (await FlutterBluePlus.isSupported == false) {
        print('Bluetooth not supported by this device');
        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('Bluetooth is not turned on. Current state: $adapterState');
        return false;
      }

      // Initialize cleanup timer
      _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _cleanupStaleBeacons();
      });

      return true;
    } catch (e) {
      print('Error initializing Mall BLE service: $e');
      return false;
    }
  }

  /// Start scanning for all mall beacons
  Future<void> startScanning() async {
    try {
      if (!await initialize()) {
        return;
      }

      if (_isScanning) {
        print('Mall scan already in progress');
        return;
      }

      await stopScanning();
      print('Starting mall-wide BLE scan...');
      _isScanning = true;

      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        withServices: [],
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _processScanResults,
        onError: (error) {
          print('Mall scan error: $error');
          _isScanning = false;
        },
      );

      // Continuous scanning for real-time positioning
      _scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!_isScanning) {
          timer.cancel();
          return;
        }
        _restartScan();
      });
    } catch (e) {
      print('Error starting mall BLE scan: $e');
      _isScanning = false;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    try {
      _isScanning = false;
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanTimer?.cancel();

      _detectedBeacons.clear();
      _beaconsController.add({});

      print('Mall BLE scan stopped');
    } catch (e) {
      print('Error stopping mall BLE scan: $e');
    }
  }

  /// Process scan results for all beacons
  void _processScanResults(List<ScanResult> results) {
    if (results.isEmpty) return;

    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) return;

    bool hasUpdates = false;

    for (final result in results) {
      final device = result.device;
      final rssi = result.rssi;
      final advertisementData = result.advertisementData;

      // Extract beacon information
      final beaconInfo =
          _extractBeaconInfo(advertisementData, device.platformName);
      if (beaconInfo == null) continue;

      final minor = beaconInfo['minor'] as int;
      final txPower = beaconInfo['txPower'] as int;

      // Find beacon configuration in mall data
      final beaconConfig = mallConfig.findBeaconByMinor(minor);
      if (beaconConfig == null) {
        // Unknown beacon, skip
        continue;
      }

      // Calculate distance
      final distance = _estimateDistance(rssi, txPower);

      // Only process beacons with reasonable RSSI
      if (rssi > rssiThreshold) {
        final beacon = Beacon(
          id: beaconConfig.id,
          uuid: beaconConfig.uuid,
          major: beaconConfig.major,
          minor: minor,
          position: beaconConfig.position,
          txPower: txPower,
          rssi: rssi,
          distance: distance,
          lastSeen: DateTime.now(),
        );

        _detectedBeacons[beacon.id] = beacon;
        hasUpdates = true;

        // Send to positioning service
        IndoorPositioningService.instance.updateBeacon(beacon);

        print('Mall beacon detected: ${beacon.id} (minor: $minor) '
            'RSSI: $rssi, distance: ${distance.toStringAsFixed(2)}m');
      }
    }

    if (hasUpdates) {
      _beaconsController.add(Map.from(_detectedBeacons));
    }
  }

  /// Extract beacon information from advertisement data
  Map<String, dynamic>? _extractBeaconInfo(
      AdvertisementData advertisementData, String deviceName) {
    // Try manufacturer data first (iBeacon format)
    final manufacturerData = advertisementData.manufacturerData;
    for (final entry in manufacturerData.entries) {
      final data = entry.value;
      if (data.length >= 23) {
        final isIBeacon = data[0] == 0x02 && data[1] == 0x15;

        if (isIBeacon) {
          final uuidBytes = data.sublist(2, 18);
          final uuidStr = _formatUuid(uuidBytes);

          if (uuidStr.toUpperCase() == targetServiceUuid.toUpperCase()) {
            final major = (data[18] << 8) | data[19];
            final minor = (data[20] << 8) | data[21];
            int txPower = data[22];
            if (txPower > 127) txPower -= 256;

            return {
              'uuid': uuidStr,
              'major': major,
              'minor': minor,
              'txPower': txPower,
            };
          }
        }
      }
    }

    // Fallback: try to extract from device name for testing
    return _simulateBeaconInfo(deviceName);
  }

  /// Format UUID bytes to string
  String _formatUuid(List<int> bytes) {
    String two(int b) => b.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(two).join();
    return '${b.substring(0, 8)}-${b.substring(8, 12)}-${b.substring(12, 16)}-${b.substring(16, 20)}-${b.substring(20)}'
        .toUpperCase();
  }

  /// Simulate beacon info for testing
  Map<String, dynamic>? _simulateBeaconInfo(String deviceName) {
    if (deviceName.isEmpty) return null;

    // Create hash-based beacon ID for testing
    final hash = deviceName.hashCode.abs();
    final minor = 101 + (hash % 20); // Generate minors 101-120

    return {
      'uuid': targetServiceUuid,
      'major': 1,
      'minor': minor,
      'txPower': -59,
    };
  }

  /// Estimate distance using RSSI and Tx Power
  double _estimateDistance(int rssi, int txPower) {
    if (rssi == 0) return 999.0;

    final ratio = rssi / txPower;
    if (ratio < 1.0) {
      return math.pow(ratio, 10).toDouble();
    } else {
      return 0.89976 * math.pow(ratio, 7.7095).toDouble() + 0.111;
    }
  }

  /// Clean up stale beacons
  void _cleanupStaleBeacons() {
    final now = DateTime.now();
    final staleBeacons = _detectedBeacons.entries
        .where((entry) => now.difference(entry.value.lastSeen) > beaconTimeout)
        .map((entry) => entry.key)
        .toList();

    bool hasChanges = false;
    for (final beaconId in staleBeacons) {
      _detectedBeacons.remove(beaconId);
      hasChanges = true;
    }

    if (hasChanges) {
      _beaconsController.add(Map.from(_detectedBeacons));
      IndoorPositioningService.instance.cleanupStaleBeacons();
    }
  }

  /// Restart scan
  Future<void> _restartScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 100));
      await FlutterBluePlus.startScan(timeout: scanTimeout);
    } catch (e) {
      print('Error restarting mall scan: $e');
    }
  }

  /// Check permissions
  Future<bool> _checkPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      return statuses.values.every(
        (status) => status == PermissionStatus.granted,
      );
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Get specific beacon by ID
  Beacon? getBeacon(String beaconId) {
    return _detectedBeacons[beaconId];
  }

  /// Get beacons by store ID
  List<Beacon> getBeaconsForStore(String storeId) {
    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) return [];

    final store = mallConfig.findStore(storeId);
    if (store == null) return [];

    return store.associatedBeacons
        .map((beaconId) => _detectedBeacons[beaconId])
        .where((beacon) => beacon != null)
        .cast<Beacon>()
        .toList();
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'is_scanning': _isScanning,
      'detected_beacons_count': _detectedBeacons.length,
      'beacons': _detectedBeacons.values
          .map((beacon) => {
                'id': beacon.id,
                'minor': beacon.minor,
                'rssi': beacon.rssi,
                'distance': beacon.distance.toStringAsFixed(2),
                'position': '(${beacon.position.x}, ${beacon.position.y})',
                'last_seen': beacon.lastSeen.toIso8601String(),
              })
          .toList(),
    };
  }

  /// Dispose resources
  void dispose() {
    stopScanning();
    _cleanupTimer?.cancel();
    _beaconsController.close();
  }
}
