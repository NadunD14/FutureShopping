import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service class to handle BLE scanning and beacon detection
class BleService {
  BleService._();
  static final instance = BleService._();

  final StreamController<String?> _activeBeaconController =
      StreamController<String?>.broadcast();
  final StreamController<Map<String, double>> _proximityController =
      StreamController<Map<String, double>>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Configuration for actual beacon detection
  static const String targetServiceUuid =
      'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0'; // Standard iBeacon UUID
  static const Duration scanTimeout =
      Duration(seconds: 3); // Reduced for faster response
  static const int rssiThreshold = -80; // More sensitive detection
  static const int hysteresisBuffer = 2; // Reduced buffer for faster switching
  static const double distanceThresholdMeters = 0.7; // Only accept <= 0.7m

  String? _currentBeaconId;
  Map<String, int> _beaconRssiHistory = {};
  final Map<String, DateTime> _beaconLastSeen = {};
  static const Duration _staleDuration = Duration(seconds: 3);
  final Map<String, int> _beaconTxPower = {}; // last known TxPower per beacon
  final Map<String, double> _beaconDistance = {}; // last estimated distance
  Timer? _scanTimer;
  bool _isScanning = false;

  /// Stream of active beacon Minor IDs
  Stream<String?> get activeBeaconStream => _activeBeaconController.stream;

  /// Stream of last estimated distances (meters) per mapped beacon id (e.g., '101','102')
  Stream<Map<String, double>> get beaconDistancesStream =>
      _proximityController.stream;

  /// Get current active beacon ID
  String? get currentBeaconId => _currentBeaconId;

  /// Check and request permissions
  Future<bool> _checkPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      bool allGranted = statuses.values.every(
        (status) => status == PermissionStatus.granted,
      );

      if (!allGranted) {
        print('Some permissions not granted: $statuses');
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Initialize BLE service and check permissions
  Future<bool> initialize() async {
    try {
      // Check permissions first
      if (!await _checkPermissions()) {
        print('Permissions not granted');
        return false;
      }

      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        print('Bluetooth not supported by this device');
        return false;
      }

      // Check Bluetooth adapter state
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('Bluetooth is not turned on. Current state: $adapterState');
        return false;
      }

      return true;
    } catch (e) {
      print('Error initializing BLE service: $e');
      return false;
    }
  }

  /// Start scanning for BLE beacons
  Future<void> startScanning() async {
    try {
      if (!await initialize()) {
        return;
      }

      // Prevent multiple concurrent scans
      if (_isScanning) {
        print('Scan already in progress');
        return;
      }

      // Stop any existing scan
      await stopScanning();

      print('Starting BLE scan...');
      _isScanning = true;

      // Start scanning with longer timeout for better detection
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        withServices: [], // Scan for all devices
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _processScanResults,
        onError: (error) {
          print('Scan error: $error');
          _isScanning = false;
        },
      );

      // Set up periodic scanning with faster intervals for responsiveness
      _scanTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!_isScanning) {
          timer.cancel();
          return;
        }
        _restartScan();
      });
    } catch (e) {
      print('Error starting BLE scan: $e');
      _isScanning = false;
    }
  }

  /// Stop BLE scanning
  Future<void> stopScanning() async {
    try {
      _isScanning = false;
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanTimer?.cancel();

      _currentBeaconId = null;
      _beaconRssiHistory.clear();
      _activeBeaconController.add(null);

      print('BLE scan stopped');
    } catch (e) {
      print('Error stopping BLE scan: $e');
    }
  }

  /// Process scan results to find strongest beacon
  void _processScanResults(List<ScanResult> results) {
    if (results.isEmpty) return;

    String? strongestBeaconId;
    int strongestRssi = rssiThreshold;

    for (final result in results) {
      final device = result.device;
      final rssi = result.rssi;
      final advertisementData = result.advertisementData;

      // Look for iBeacon data in manufacturer data
      String? beaconId =
          _extractBeaconId(advertisementData, device.platformName);

      if (beaconId != null) {
        // Map the detected beacon ID to product ID
        String? mappedId = _mapBeaconToProduct(beaconId);
        if (mappedId != null) {
          // Estimate distance (prefer parsed TxPower, fallback to -59)
          final tx = _beaconTxPower[mappedId] ?? -59;
          final distance = _estimateDistance(rssi, tx);
          _beaconDistance[mappedId] = distance;
          // Emit current distances snapshot
          _proximityController.add(Map<String, double>.from(_beaconDistance));

          if (distance <= distanceThresholdMeters && rssi > strongestRssi) {
            strongestBeaconId = mappedId;
            strongestRssi = rssi;
            _beaconRssiHistory[mappedId] = rssi;
            _beaconLastSeen[mappedId] = DateTime.now();

            print(
                'Found beacon: $beaconId => product: $mappedId RSSI: $rssi, Tx: $tx, d≈${distance.toStringAsFixed(2)}m');
          } else {
            // Debug out-of-range beacons
            print(
                'Ignoring $beaconId=>${mappedId} d≈${distance.toStringAsFixed(2)}m (> ${distanceThresholdMeters}m)');
          }
        }
      }
    }

    if (strongestBeaconId != null) {
      _updateActiveBeacon(strongestBeaconId, strongestRssi);
    }

    // Clear current beacon if it hasn't been seen recently
    _clearStaleBeaconIfNeeded();

    // Also clear if current beacon is beyond distance threshold
    _clearFarBeaconIfNeeded();
  }

  /// Extract beacon ID (Minor) from advertisement data or device name
  ///
  /// iBeacon manufacturer data layout (value bytes):
  /// [0] = 0x02, [1] = 0x15, [2..17] = UUID (16 bytes),
  /// [18..19] = Major (BE), [20..21] = Minor (BE), [22] = Tx Power
  String? _extractBeaconId(
      AdvertisementData advertisementData, String deviceName) {
    // 1) Try to extract from manufacturer data (iBeacon format)
    final manufacturerData = advertisementData.manufacturerData;
    for (final entry in manufacturerData.entries) {
      final data = entry.value;
      // Expect at least 23 bytes for iBeacon payload
      if (data.length >= 23) {
        // Validate iBeacon prefix if available
        final isIBeacon = data[0] == 0x02 && data[1] == 0x15;
        // Indices per iBeacon spec
        final uuidStart = 2;
        // final majorStart = 18; // kept for reference
        final minorStart = 20;
        final txPowerIndex = 22;

        // Parse UUID to string for validation (optional but helpful for debugging)
        if (isIBeacon) {
          final uuidBytes = data.sublist(uuidStart, uuidStart + 16);
          final uuidStr = _formatUuid(uuidBytes);

          // If UUID is provided in config, prefer matches (ignore case)
          if (uuidStr.toUpperCase() == targetServiceUuid.toUpperCase()) {
            final minor = (data[minorStart] << 8) | data[minorStart + 1];
            // Tx Power is signed int8
            int tx = data[txPowerIndex];
            if (tx > 127) tx -= 256;
            _beaconTxPower[minor.toString()] = tx;
            // final major = (data[majorStart] << 8) | data[majorStart + 1];
            // Log once per detection for clarity
            // print('iBeacon detected UUID:$uuidStr Major:$major Minor:$minor');
            if (minor > 0) return minor.toString();
          } else {
            // UUID doesn't match our target, but still parse minor as a fallback
            final minor = (data[minorStart] << 8) | data[minorStart + 1];
            int tx = data[txPowerIndex];
            if (tx > 127) tx -= 256;
            _beaconTxPower[minor.toString()] = tx;
            if (minor > 0) return minor.toString();
          }
        } else {
          // Some simulators omit the 0x02,0x15 prefix in value; try best-effort parse by aligning to end
          // Assume last 3 bytes are [minor_hi, minor_lo, txPower]
          final minorHi = data[data.length - 3];
          final minorLo = data[data.length - 2];
          final minor = (minorHi << 8) | minorLo;
          int tx = data.last;
          if (tx > 127) tx -= 256;
          _beaconTxPower[minor.toString()] = tx;
          if (minor > 0) return minor.toString();
        }
      }
    }

    // Fallback: try to extract from device name patterns
    if (deviceName.isNotEmpty) {
      // Look for patterns like "Beacon_101", "iBeacon101", etc.
      final beaconPattern = RegExp(r'[Bb]eacon[_\-]?(\d+)');
      final match = beaconPattern.firstMatch(deviceName);
      if (match != null) {
        return match.group(1);
      }

      // Look for simple numeric patterns
      final numPattern = RegExp(r'(\d+)');
      final numMatch = numPattern.firstMatch(deviceName);
      if (numMatch != null) {
        return numMatch.group(1);
      }
    }

    // 3) For testing: simulate beacon IDs based on device name
    return _simulateBeaconId(deviceName);
  }

  /// Estimate distance (meters) using RSSI and Tx Power (iBeacon style)
  double _estimateDistance(int rssi, int txPower) {
    if (rssi == 0) return 999.0; // cannot determine
    final ratio = rssi / txPower;
    if (ratio < 1.0) {
      return math.pow(ratio, 12).toDouble(); // Higher exponent
    } else {
      return 0.69976 * math.pow(ratio, 10).toDouble() +
          0.111; // Smaller constant
    }
  }

  void _clearFarBeaconIfNeeded() {
    if (_currentBeaconId == null) return;
    final d = _beaconDistance[_currentBeaconId!];
    if (d != null && d > distanceThresholdMeters) {
      _currentBeaconId = null;
      _activeBeaconController.add(null);
      print(
          'Active beacon cleared (distance ${d.toStringAsFixed(2)}m > ${distanceThresholdMeters}m)');
    }
  }

  /// Format 16-byte UUID into canonical 8-4-4-4-12 hex string
  String _formatUuid(List<int> bytes) {
    String two(int b) => b.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(two).join();
    return '${b.substring(0, 8)}-${b.substring(8, 12)}-${b.substring(12, 16)}-${b.substring(16, 20)}-${b.substring(20)}'
        .toUpperCase();
  }

  /// Simulate beacon ID for testing purposes
  String? _simulateBeaconId(String deviceName) {
    if (deviceName.isEmpty) return null;

    // Create a simple hash-based beacon ID for testing
    final hash = deviceName.hashCode.abs();
    final beaconId = 101 + (hash % 10); // Generate IDs between 101-110
    return beaconId.toString();
  }

  /// Map detected beacon values to product IDs
  String? _mapBeaconToProduct(String beaconId) {
    // Map both direct minors and your hardware minors to two shops:
    // 101 => Clothing, 102 => Electrical
    switch (beaconId) {
      case '101':
      case '25864':
        return '101';
      case '102':
      case '26120':
        return '102';
      default:
        return null;
    }
  }

  /// Update active beacon with hysteresis logic
  void _updateActiveBeacon(String beaconId, int rssi) {
    // Update last seen for candidate
    _beaconLastSeen[beaconId] = DateTime.now();

    if (_currentBeaconId == null) {
      // No current beacon, set this one
      _setActiveBeacon(beaconId);
    } else if (_currentBeaconId == beaconId) {
      // Same beacon, just update RSSI
      _beaconRssiHistory[beaconId] = rssi;
    } else {
      // Different beacon, check if it's significantly stronger
      final currentId = _currentBeaconId!;
      int currentRssi = _beaconRssiHistory[currentId] ?? rssiThreshold;
      final lastSeen = _beaconLastSeen[currentId];
      final isStale = lastSeen == null ||
          DateTime.now().difference(lastSeen) > _staleDuration;

      // If current is stale, switch immediately
      if (isStale) {
        _setActiveBeacon(beaconId);
        return;
      }

      if (rssi > currentRssi + hysteresisBuffer) {
        _setActiveBeacon(beaconId);
      }
    }
  }

  /// Set a new active beacon
  void _setActiveBeacon(String beaconId) {
    if (_currentBeaconId != beaconId) {
      _currentBeaconId = beaconId;
      _activeBeaconController.add(beaconId);
      print('Active beacon changed to: $beaconId');
    }
  }

  void _clearStaleBeaconIfNeeded() {
    if (_currentBeaconId == null) return;
    final lastSeen = _beaconLastSeen[_currentBeaconId!];
    if (lastSeen == null) return;
    if (DateTime.now().difference(lastSeen) > _staleDuration) {
      // Clear current beacon when stale so UI can reset
      _currentBeaconId = null;
      _activeBeaconController.add(null);
      print('Active beacon cleared due to staleness');
    }
  }

  /// Restart scan after timeout
  Future<void> _restartScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 200)); // Faster restart
      await FlutterBluePlus.startScan(timeout: scanTimeout);
    } catch (e) {
      print('Error restarting scan: $e');
    }
  }

  /// Dispose and cleanup
  void dispose() {
    stopScanning();
    _activeBeaconController.close();
    _proximityController.close();
  }

  /// Simulate beacon detection for testing
  void simulateBeaconDetection(String beaconId) {
    _setActiveBeacon(beaconId);
  }

  /// Check if BLE is available and enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      print('Error checking Bluetooth state: $e');
      return false;
    }
  }
}
