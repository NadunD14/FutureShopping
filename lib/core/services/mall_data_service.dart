import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/positioning_models.dart';

/// Service for managing mall configuration and data
class MallDataService {
  MallDataService._();
  static final instance = MallDataService._();

  MallConfig? _mallConfig;
  bool _isInitialized = false;

  /// Get current mall configuration
  MallConfig? get mallConfig => _mallConfig;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize mall data from JSON configuration
  Future<bool> initialize(
      {String configPath = 'assets/mall_config.json'}) async {
    try {
      print('Loading mall configuration from $configPath...');

      // Load JSON configuration
      final jsonString = await rootBundle.loadString(configPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Parse mall configuration
      _mallConfig = _parseMallConfig(jsonData);
      _isInitialized = true;

      print('Mall configuration loaded successfully:');
      print('- ${_mallConfig!.name}');
      print('- ${_mallConfig!.beacons.length} beacons');
      print('- ${_mallConfig!.stores.length} stores');

      return true;
    } catch (e) {
      print('Error loading mall configuration: $e');
      return false;
    }
  }

  /// Parse mall configuration from JSON
  MallConfig _parseMallConfig(Map<String, dynamic> json) {
    final config = json['mall_config'] as Map<String, dynamic>;
    final bounds = config['bounds'] as Map<String, dynamic>;

    // Parse beacons
    final beaconsList = json['beacons'] as List<dynamic>;
    final beacons = beaconsList.map((beaconJson) {
      final beacon = beaconJson as Map<String, dynamic>;
      final position = beacon['position'] as Map<String, dynamic>;

      return Beacon(
        id: beacon['id'] as String,
        uuid: beacon['uuid'] as String,
        major: beacon['major'] as int,
        minor: beacon['minor'] as int,
        position: Position(
          x: (position['x'] as num).toDouble(),
          y: (position['y'] as num).toDouble(),
          accuracy: 0.0,
          timestamp: DateTime.now(),
          floorLevel: beacon['floor_level'] as int? ?? 1,
        ),
        txPower: beacon['tx_power'] as int,
        rssi: 0, // Will be updated during scanning
        distance: 0.0, // Will be calculated during scanning
        lastSeen: DateTime.now(),
      );
    }).toList();

    // Parse stores
    final storesList = json['stores'] as List<dynamic>;
    final stores = storesList.map((storeJson) {
      final store = storeJson as Map<String, dynamic>;
      final polygonList = store['polygon'] as List<dynamic>;
      final entrancePoint = store['entrance_point'] as Map<String, dynamic>;
      final associatedBeacons = (store['associated_beacons'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      return Store(
        id: store['id'] as String,
        name: store['name'] as String,
        category: store['category'] as String,
        polygon: polygonList.map((point) {
          final p = point as Map<String, dynamic>;
          return MapPoint(
            x: (p['x'] as num).toDouble(),
            y: (p['y'] as num).toDouble(),
          );
        }).toList(),
        entrancePoint: MapPoint(
          x: (entrancePoint['x'] as num).toDouble(),
          y: (entrancePoint['y'] as num).toDouble(),
        ),
        associatedBeacons: associatedBeacons,
        floorLevel: store['floor_level'] as int? ?? 1,
      );
    }).toList();

    // Parse pathfinding graph
    final graphData = json['pathfinding_graph'] as Map<String, dynamic>;
    final nodes = graphData['nodes'] as List<dynamic>;
    final edges = graphData['edges'] as List<dynamic>;

    final graphNodes = <String, MapPoint>{};
    for (final nodeJson in nodes) {
      final node = nodeJson as Map<String, dynamic>;
      graphNodes[node['id'] as String] = MapPoint(
        x: (node['x'] as num).toDouble(),
        y: (node['y'] as num).toDouble(),
      );
    }

    final pathfindingGraph = <String, List<String>>{};
    for (final edgeJson in edges) {
      final edge = edgeJson as Map<String, dynamic>;
      final from = edge['from'] as String;
      final to = edge['to'] as String;

      pathfindingGraph.putIfAbsent(from, () => []).add(to);
      pathfindingGraph.putIfAbsent(to, () => []).add(from); // Bidirectional
    }

    return MallConfig(
      id: config['id'] as String,
      name: config['name'] as String,
      minBounds: MapPoint(
        x: (bounds['min_x'] as num).toDouble(),
        y: (bounds['min_y'] as num).toDouble(),
      ),
      maxBounds: MapPoint(
        x: (bounds['max_x'] as num).toDouble(),
        y: (bounds['max_y'] as num).toDouble(),
      ),
      pixelToMeterRatio: (config['pixel_to_meter_ratio'] as num).toDouble(),
      beacons: beacons,
      stores: stores,
      pathfindingGraph: pathfindingGraph,
      graphNodes: graphNodes,
    );
  }

  /// Initialize with sample data for testing
  Future<bool> initializeWithSampleData() async {
    try {
      print('Initializing with sample mall data...');

      _mallConfig = _createSampleMallConfig();
      _isInitialized = true;

      print('Sample mall configuration loaded:');
      print('- ${_mallConfig!.name}');
      print('- ${_mallConfig!.beacons.length} beacons');
      print('- ${_mallConfig!.stores.length} stores');

      return true;
    } catch (e) {
      print('Error creating sample mall data: $e');
      return false;
    }
  }

  /// Create sample mall configuration for testing
  MallConfig _createSampleMallConfig() {
    final now = DateTime.now();

    // Sample beacons positioned around the mall
    final beacons = [
      Beacon(
        id: 'beacon_001',
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        major: 1,
        minor: 101,
        position:
            Position(x: 50, y: 50, accuracy: 0, timestamp: now, floorLevel: 1),
        txPower: -59,
        rssi: 0,
        distance: 0.0,
        lastSeen: now,
      ),
      Beacon(
        id: 'beacon_002',
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        major: 1,
        minor: 102,
        position:
            Position(x: 150, y: 50, accuracy: 0, timestamp: now, floorLevel: 1),
        txPower: -59,
        rssi: 0,
        distance: 0.0,
        lastSeen: now,
      ),
      Beacon(
        id: 'beacon_003',
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        major: 1,
        minor: 103,
        position:
            Position(x: 250, y: 50, accuracy: 0, timestamp: now, floorLevel: 1),
        txPower: -59,
        rssi: 0,
        distance: 0.0,
        lastSeen: now,
      ),
      Beacon(
        id: 'beacon_004',
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        major: 1,
        minor: 104,
        position:
            Position(x: 50, y: 150, accuracy: 0, timestamp: now, floorLevel: 1),
        txPower: -59,
        rssi: 0,
        distance: 0.0,
        lastSeen: now,
      ),
      Beacon(
        id: 'beacon_005',
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        major: 1,
        minor: 105,
        position: Position(
            x: 250, y: 150, accuracy: 0, timestamp: now, floorLevel: 1),
        txPower: -59,
        rssi: 0,
        distance: 0.0,
        lastSeen: now,
      ),
    ];

    // Sample stores
    final stores = [
      Store(
        id: 'store_001',
        name: 'Apple Store',
        category: 'Electronics',
        polygon: const [
          MapPoint(x: 40, y: 40),
          MapPoint(x: 60, y: 40),
          MapPoint(x: 60, y: 60),
          MapPoint(x: 40, y: 60),
        ],
        entrancePoint: const MapPoint(x: 50, y: 40),
        associatedBeacons: ['beacon_001'],
        floorLevel: 1,
      ),
      Store(
        id: 'store_002',
        name: 'Nike Store',
        category: 'Fashion',
        polygon: const [
          MapPoint(x: 140, y: 40),
          MapPoint(x: 160, y: 40),
          MapPoint(x: 160, y: 60),
          MapPoint(x: 140, y: 60),
        ],
        entrancePoint: const MapPoint(x: 150, y: 40),
        associatedBeacons: ['beacon_002'],
        floorLevel: 1,
      ),
      Store(
        id: 'store_003',
        name: 'Starbucks',
        category: 'Food & Beverage',
        polygon: const [
          MapPoint(x: 240, y: 40),
          MapPoint(x: 260, y: 40),
          MapPoint(x: 260, y: 60),
          MapPoint(x: 240, y: 60),
        ],
        entrancePoint: const MapPoint(x: 250, y: 40),
        associatedBeacons: ['beacon_003'],
        floorLevel: 1,
      ),
    ];

    // Simple pathfinding graph
    final graphNodes = {
      'n1': const MapPoint(x: 50, y: 30),
      'n2': const MapPoint(x: 150, y: 30),
      'n3': const MapPoint(x: 250, y: 30),
      'n4': const MapPoint(x: 50, y: 70),
      'n5': const MapPoint(x: 150, y: 70),
      'n6': const MapPoint(x: 250, y: 70),
      'n7': const MapPoint(x: 50, y: 130),
      'n8': const MapPoint(x: 150, y: 130),
      'n9': const MapPoint(x: 250, y: 130),
    };

    final pathfindingGraph = {
      'n1': ['n2', 'n4'],
      'n2': ['n1', 'n3', 'n5'],
      'n3': ['n2', 'n6'],
      'n4': ['n1', 'n5', 'n7'],
      'n5': ['n2', 'n4', 'n6', 'n8'],
      'n6': ['n3', 'n5', 'n9'],
      'n7': ['n4', 'n8'],
      'n8': ['n5', 'n7', 'n9'],
      'n9': ['n6', 'n8'],
    };

    return MallConfig(
      id: 'sample_mall',
      name: 'Sample Mall for Testing',
      minBounds: const MapPoint(x: 0, y: 0),
      maxBounds: const MapPoint(x: 300, y: 200),
      pixelToMeterRatio: 10.0,
      beacons: beacons,
      stores: stores,
      pathfindingGraph: pathfindingGraph,
      graphNodes: graphNodes,
    );
  }

  /// Find nearest store to a position
  Store? findNearestStore(Position position) {
    if (_mallConfig == null) return null;

    Store? nearestStore;
    double minDistance = double.infinity;

    for (final store in _mallConfig!.stores) {
      if (store.floorLevel != position.floorLevel) continue;

      final distance = position.distanceTo(Position(
        x: store.entrancePoint.x,
        y: store.entrancePoint.y,
        accuracy: 0,
        timestamp: DateTime.now(),
        floorLevel: store.floorLevel,
      ));

      if (distance < minDistance) {
        minDistance = distance;
        nearestStore = store;
      }
    }

    return nearestStore;
  }

  /// Search stores by name or category
  List<Store> searchStores(String query) {
    if (_mallConfig == null) return [];

    final lowerQuery = query.toLowerCase();
    return _mallConfig!.stores.where((store) {
      return store.name.toLowerCase().contains(lowerQuery) ||
          store.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get all stores in a category
  List<Store> getStoresByCategory(String category) {
    if (_mallConfig == null) return [];

    return _mallConfig!.stores
        .where(
            (store) => store.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get all available categories
  List<String> getCategories() {
    if (_mallConfig == null) return [];

    return _mallConfig!.stores.map((store) => store.category).toSet().toList()
      ..sort();
  }

  /// Reset service
  void reset() {
    _mallConfig = null;
    _isInitialized = false;
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'is_initialized': _isInitialized,
      'mall_name': _mallConfig?.name,
      'beacons_count': _mallConfig?.beacons.length ?? 0,
      'stores_count': _mallConfig?.stores.length ?? 0,
      'categories': getCategories(),
    };
  }
}
