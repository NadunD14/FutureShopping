import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/positioning_models.dart';
import 'mall_data_service.dart';
import 'mall_ble_service.dart';
import 'indoor_positioning_service.dart';
import 'navigation_mode_manager.dart';

/// Example service that demonstrates how to integrate all the mall navigation components
class MallNavigationExampleService {
  MallNavigationExampleService._();
  static final instance = MallNavigationExampleService._();

  bool _isInitialized = false;

  /// Initialize all navigation services
  Future<bool> initializeAll() async {
    if (_isInitialized) return true;

    try {
      print('🏪 Initializing Mall Navigation System...');

      // Step 1: Load mall configuration
      print('📋 Loading mall configuration...');
      final mallDataLoaded =
          await MallDataService.instance.initializeWithSampleData();
      if (!mallDataLoaded) {
        print('❌ Failed to load mall data');
        return false;
      }
      print('✅ Mall data loaded successfully');

      // Step 2: Initialize positioning service
      print('📍 Initializing indoor positioning...');
      IndoorPositioningService.instance.reset();
      print('✅ Indoor positioning ready');

      // Step 3: Initialize navigation mode manager
      print('🧭 Initializing navigation mode manager...');
      await NavigationModeManager.instance.initialize();
      print('✅ Navigation mode manager ready');

      // Step 4: Initialize BLE service
      print('📡 Initializing BLE service...');
      final bleReady = await MallBleService.instance.initialize();
      if (!bleReady) {
        print('⚠️  BLE service not ready (permissions/hardware issue)');
        // Continue anyway for testing
      } else {
        print('✅ BLE service ready');
      }

      _isInitialized = true;
      print('🎉 Mall Navigation System initialized successfully!');
      return true;
    } catch (e) {
      print('❌ Error initializing Mall Navigation System: $e');
      return false;
    }
  }

  /// Start mall navigation (scanning for all beacons)
  Future<void> startMallNavigation() async {
    if (!_isInitialized) {
      await initializeAll();
    }

    print('🚀 Starting mall navigation...');
    await MallBleService.instance.startScanning();
    print('✅ Mall navigation started - scanning for beacons');
  }

  /// Stop mall navigation
  Future<void> stopMallNavigation() async {
    print('🛑 Stopping mall navigation...');
    await MallBleService.instance.stopScanning();
    NavigationModeManager.instance.clearNavigation();
    print('✅ Mall navigation stopped');
  }

  /// Navigate to a specific store
  Future<bool> navigateToStore(String storeId) async {
    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) {
      print('❌ Mall configuration not loaded');
      return false;
    }

    final store = mallConfig.findStore(storeId);
    if (store == null) {
      print('❌ Store not found: $storeId');
      return false;
    }

    print('🎯 Navigating to ${store.name}...');
    final success = await NavigationModeManager.instance.navigateToStore(store);

    if (success) {
      print('✅ Navigation path calculated to ${store.name}');
    } else {
      print('❌ Failed to calculate path to ${store.name}');
    }

    return success;
  }

  /// Search for stores
  List<Store> searchStores(String query) {
    return NavigationModeManager.instance.searchStores(query);
  }

  /// Get stores by category
  List<Store> getStoresByCategory(String category) {
    return NavigationModeManager.instance.getStoresByCategory(category);
  }

  /// Get comprehensive system status
  Map<String, dynamic> getSystemStatus() {
    final mallConfig = MallDataService.instance.mallConfig;
    final currentPosition = IndoorPositioningService.instance.currentPosition;
    final modeInfo = NavigationModeManager.instance.getCurrentModeInfo();

    return {
      'initialized': _isInitialized,
      'mall_config': {
        'loaded': mallConfig != null,
        'name': mallConfig?.name,
        'beacons_count': mallConfig?.beacons.length ?? 0,
        'stores_count': mallConfig?.stores.length ?? 0,
      },
      'positioning': {
        'current_position': currentPosition?.toString(),
        'accuracy': currentPosition?.accuracy,
        'floor_level': currentPosition?.floorLevel,
      },
      'ble_service': MallBleService.instance.getDebugInfo(),
      'navigation': modeInfo,
      'indoor_positioning': IndoorPositioningService.instance.getDebugInfo(),
    };
  }

  /// Simulate beacon detection for testing
  void simulateBeaconDetection(int minor, int rssi) {
    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) return;

    final beaconConfig = mallConfig.findBeaconByMinor(minor);
    if (beaconConfig == null) {
      print('⚠️  Unknown beacon minor: $minor');
      return;
    }

    // Calculate distance from RSSI
    final distance = _estimateDistance(rssi, beaconConfig.txPower);

    final beacon = Beacon(
      id: beaconConfig.id,
      uuid: beaconConfig.uuid,
      major: beaconConfig.major,
      minor: minor,
      position: beaconConfig.position,
      txPower: beaconConfig.txPower,
      rssi: rssi,
      distance: distance,
      lastSeen: DateTime.now(),
    );

    IndoorPositioningService.instance.updateBeacon(beacon);
    print(
        '📡 Simulated beacon: ${beacon.id} (minor: $minor, RSSI: $rssi, distance: ${distance.toStringAsFixed(2)}m)');
  }

  /// Test positioning with multiple simulated beacons
  void testPositioning() {
    print('🧪 Testing positioning with simulated beacons...');

    // Simulate detecting multiple beacons with different signal strengths
    simulateBeaconDetection(101, -65); // Close to beacon 1
    simulateBeaconDetection(102, -75); // Medium distance to beacon 2
    simulateBeaconDetection(103, -85); // Far from beacon 3

    // Wait a bit then add more beacons
    Future.delayed(const Duration(seconds: 2), () {
      simulateBeaconDetection(104, -70); // Medium distance to beacon 4
      simulateBeaconDetection(105, -80); // Far from beacon 5
    });
  }

  /// Test navigation to a store
  void testNavigation() {
    print('🧪 Testing navigation...');

    // First ensure we have positioning
    testPositioning();

    // Then navigate to a store after positioning stabilizes
    Future.delayed(const Duration(seconds: 3), () {
      navigateToStore('store_003'); // Navigate to Starbucks
    });
  }

  double _estimateDistance(int rssi, int txPower) {
    if (rssi == 0) return 999.0;

    final ratio = rssi / txPower;
    if (ratio < 1.0) {
      return math.pow(ratio, 10).toDouble();
    } else {
      return 0.89976 * math.pow(ratio, 7.7095).toDouble() + 0.111;
    }
  }

  /// Dispose all services
  void dispose() {
    print('🧹 Disposing Mall Navigation System...');

    MallBleService.instance.dispose();
    IndoorPositioningService.instance.dispose();
    NavigationModeManager.instance.dispose();

    _isInitialized = false;
    print('✅ Mall Navigation System disposed');
  }
}

/// Provider for mall navigation state
final mallNavigationProvider =
    StateNotifierProvider<MallNavigationNotifier, MallNavigationState>((ref) {
  return MallNavigationNotifier();
});

class MallNavigationState {
  final bool isInitialized;
  final NavigationMode mode;
  final Position? currentPosition;
  final Store? currentStore;
  final Store? targetStore;
  final List<MapPoint>? currentPath;
  final Map<String, Beacon> detectedBeacons;

  const MallNavigationState({
    this.isInitialized = false,
    this.mode = NavigationMode.mallNavigation,
    this.currentPosition,
    this.currentStore,
    this.targetStore,
    this.currentPath,
    this.detectedBeacons = const {},
  });

  MallNavigationState copyWith({
    bool? isInitialized,
    NavigationMode? mode,
    Position? currentPosition,
    Store? currentStore,
    Store? targetStore,
    List<MapPoint>? currentPath,
    Map<String, Beacon>? detectedBeacons,
  }) {
    return MallNavigationState(
      isInitialized: isInitialized ?? this.isInitialized,
      mode: mode ?? this.mode,
      currentPosition: currentPosition ?? this.currentPosition,
      currentStore: currentStore ?? this.currentStore,
      targetStore: targetStore ?? this.targetStore,
      currentPath: currentPath ?? this.currentPath,
      detectedBeacons: detectedBeacons ?? this.detectedBeacons,
    );
  }
}

class MallNavigationNotifier extends StateNotifier<MallNavigationState> {
  MallNavigationNotifier() : super(const MallNavigationState()) {
    _initializeListeners();
  }

  void _initializeListeners() {
    // Listen to position updates
    IndoorPositioningService.instance.positionStream.listen((position) {
      state = state.copyWith(currentPosition: position);
    });

    // Listen to mode changes
    NavigationModeManager.instance.modeStream.listen((mode) {
      state = state.copyWith(mode: mode);
    });

    // Listen to current store changes
    NavigationModeManager.instance.currentStoreStream.listen((store) {
      state = state.copyWith(currentStore: store);
    });

    // Listen to path changes
    NavigationModeManager.instance.currentPathStream.listen((path) {
      state = state.copyWith(currentPath: path);
    });

    // Listen to beacon updates
    MallBleService.instance.beaconsStream.listen((beacons) {
      state = state.copyWith(detectedBeacons: beacons);
    });
  }

  Future<void> initialize() async {
    final success = await MallNavigationExampleService.instance.initializeAll();
    state = state.copyWith(isInitialized: success);
  }

  Future<void> startNavigation() async {
    await MallNavigationExampleService.instance.startMallNavigation();
  }

  Future<void> stopNavigation() async {
    await MallNavigationExampleService.instance.stopMallNavigation();
  }

  Future<bool> navigateToStore(String storeId) async {
    final success =
        await MallNavigationExampleService.instance.navigateToStore(storeId);
    if (success) {
      final mallConfig = MallDataService.instance.mallConfig;
      final store = mallConfig?.findStore(storeId);
      state = state.copyWith(targetStore: store);
    }
    return success;
  }

  void clearNavigation() {
    NavigationModeManager.instance.clearNavigation();
    state = state.copyWith(targetStore: null, currentPath: null);
  }

  void simulateBeacon(int minor, int rssi) {
    MallNavigationExampleService.instance.simulateBeaconDetection(minor, rssi);
  }
}
