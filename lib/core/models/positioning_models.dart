import 'dart:math' as math;

/// Position model for indoor navigation
class Position {
  final double x;
  final double y;
  final double accuracy; // Estimated accuracy in meters
  final DateTime timestamp;
  final int floorLevel;

  const Position({
    required this.x,
    required this.y,
    required this.accuracy,
    required this.timestamp,
    this.floorLevel = 1,
  });

  Position copyWith({
    double? x,
    double? y,
    double? accuracy,
    DateTime? timestamp,
    int? floorLevel,
  }) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      floorLevel: floorLevel ?? this.floorLevel,
    );
  }

  /// Calculate distance to another position
  double distanceTo(Position other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Check if position is inside a polygon (store area)
  bool isInsidePolygon(List<MapPoint> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].x;
      final yi = polygon[i].y;
      final xj = polygon[j].x;
      final yj = polygon[j].y;

      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  @override
  String toString() =>
      'Position(x: $x, y: $y, accuracy: $accuracy, floor: $floorLevel)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          floorLevel == other.floorLevel;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ floorLevel.hashCode;
}

/// Beacon model with positioning information
class Beacon {
  final String id;
  final String uuid;
  final int major;
  final int minor;
  final Position position;
  final int txPower;
  final int rssi;
  final double distance;
  final DateTime lastSeen;

  const Beacon({
    required this.id,
    required this.uuid,
    required this.major,
    required this.minor,
    required this.position,
    required this.txPower,
    required this.rssi,
    required this.distance,
    required this.lastSeen,
  });

  Beacon copyWith({
    String? id,
    String? uuid,
    int? major,
    int? minor,
    Position? position,
    int? txPower,
    int? rssi,
    double? distance,
    DateTime? lastSeen,
  }) {
    return Beacon(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      major: major ?? this.major,
      minor: minor ?? this.minor,
      position: position ?? this.position,
      txPower: txPower ?? this.txPower,
      rssi: rssi ?? this.rssi,
      distance: distance ?? this.distance,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// Check if beacon data is fresh (within last 5 seconds)
  bool get isFresh => DateTime.now().difference(lastSeen).inSeconds < 5;

  @override
  String toString() =>
      'Beacon(id: $id, minor: $minor, rssi: $rssi, distance: ${distance.toStringAsFixed(2)}m)';
}

/// Map point for defining polygons and paths
class MapPoint {
  final double x;
  final double y;

  const MapPoint({required this.x, required this.y});

  MapPoint copyWith({double? x, double? y}) {
    return MapPoint(x: x ?? this.x, y: y ?? this.y);
  }

  /// Calculate distance to another point
  double distanceTo(MapPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'MapPoint(x: $x, y: $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Store model with polygon area
class Store {
  final String id;
  final String name;
  final String category;
  final List<MapPoint> polygon;
  final MapPoint entrancePoint;
  final List<String> associatedBeacons;
  final int floorLevel;

  const Store({
    required this.id,
    required this.name,
    required this.category,
    required this.polygon,
    required this.entrancePoint,
    required this.associatedBeacons,
    this.floorLevel = 1,
  });

  /// Check if a position is inside this store
  bool containsPosition(Position position) {
    return position.floorLevel == floorLevel &&
        position.isInsidePolygon(polygon);
  }

  @override
  String toString() => 'Store(id: $id, name: $name)';
}

/// Mall configuration model
class MallConfig {
  final String id;
  final String name;
  final MapPoint minBounds;
  final MapPoint maxBounds;
  final double pixelToMeterRatio;
  final List<Beacon> beacons;
  final List<Store> stores;
  final Map<String, List<String>>
      pathfindingGraph; // node_id -> [connected_node_ids]
  final Map<String, MapPoint> graphNodes; // node_id -> position

  const MallConfig({
    required this.id,
    required this.name,
    required this.minBounds,
    required this.maxBounds,
    required this.pixelToMeterRatio,
    required this.beacons,
    required this.stores,
    required this.pathfindingGraph,
    required this.graphNodes,
  });

  /// Find store by ID
  Store? findStore(String storeId) {
    try {
      return stores.firstWhere((store) => store.id == storeId);
    } catch (e) {
      return null;
    }
  }

  /// Find store containing a position
  Store? findStoreAtPosition(Position position) {
    try {
      return stores.firstWhere((store) => store.containsPosition(position));
    } catch (e) {
      return null;
    }
  }

  /// Get beacon by minor ID
  Beacon? findBeaconByMinor(int minor) {
    try {
      return beacons.firstWhere((beacon) => beacon.minor == minor);
    } catch (e) {
      return null;
    }
  }
}
