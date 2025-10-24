import 'dart:math' as math;
import '../models/positioning_models.dart';
import 'mall_data_service.dart';

/// Pathfinding service using A* algorithm for mall navigation
class PathfindingService {
  PathfindingService._();
  static final instance = PathfindingService._();

  /// Find path from current position to target store
  List<MapPoint>? findPath(Position from, Store targetStore) {
    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) return null;

    // Find nearest graph node to start position
    final startNode =
        _findNearestNode(MapPoint(x: from.x, y: from.y), mallConfig);
    if (startNode == null) return null;

    // Find nearest graph node to target store entrance
    final endNode = _findNearestNode(targetStore.entrancePoint, mallConfig);
    if (endNode == null) return null;

    // Use A* algorithm to find path
    final pathNodes = _aStarSearch(startNode, endNode, mallConfig);
    if (pathNodes == null) return null;

    // Convert node IDs to map points and add start/end positions
    final path = <MapPoint>[
      MapPoint(x: from.x, y: from.y), // Start at current position
    ];

    // Add intermediate nodes
    for (final nodeId in pathNodes) {
      final nodePos = mallConfig.graphNodes[nodeId];
      if (nodePos != null) {
        path.add(nodePos);
      }
    }

    // Add target store entrance
    path.add(targetStore.entrancePoint);

    return _smoothPath(path);
  }

  /// Find path between two arbitrary points
  List<MapPoint>? findPathBetweenPoints(MapPoint from, MapPoint to) {
    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) return null;

    final startNode = _findNearestNode(from, mallConfig);
    final endNode = _findNearestNode(to, mallConfig);

    if (startNode == null || endNode == null) return null;

    final pathNodes = _aStarSearch(startNode, endNode, mallConfig);
    if (pathNodes == null) return null;

    final path = <MapPoint>[from];

    for (final nodeId in pathNodes) {
      final nodePos = mallConfig.graphNodes[nodeId];
      if (nodePos != null) {
        path.add(nodePos);
      }
    }

    path.add(to);
    return _smoothPath(path);
  }

  /// A* pathfinding algorithm implementation
  List<String>? _aStarSearch(
      String startNode, String endNode, MallConfig mallConfig) {
    final openSet =
        PriorityQueue<_AStarNode>((a, b) => a.fScore.compareTo(b.fScore));
    final closedSet = <String>{};
    final gScore = <String, double>{};
    final fScore = <String, double>{};
    final cameFrom = <String, String>{};

    // Initialize scores
    for (final nodeId in mallConfig.graphNodes.keys) {
      gScore[nodeId] = double.infinity;
      fScore[nodeId] = double.infinity;
    }

    gScore[startNode] = 0.0;
    fScore[startNode] = _heuristic(startNode, endNode, mallConfig);

    openSet.add(_AStarNode(startNode, fScore[startNode]!));

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      final currentNode = current.nodeId;

      if (currentNode == endNode) {
        // Reconstruct path
        return _reconstructPath(cameFrom, currentNode);
      }

      closedSet.add(currentNode);

      // Check neighbors
      final neighbors = mallConfig.pathfindingGraph[currentNode] ?? [];
      for (final neighbor in neighbors) {
        if (closedSet.contains(neighbor)) continue;

        final tentativeGScore = gScore[currentNode]! +
            _getDistance(currentNode, neighbor, mallConfig);

        if (tentativeGScore < gScore[neighbor]!) {
          cameFrom[neighbor] = currentNode;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] =
              gScore[neighbor]! + _heuristic(neighbor, endNode, mallConfig);

          // Add to open set if not already there
          if (!openSet.any((node) => node.nodeId == neighbor)) {
            openSet.add(_AStarNode(neighbor, fScore[neighbor]!));
          }
        }
      }
    }

    return null; // No path found
  }

  /// Reconstruct path from A* search
  List<String> _reconstructPath(Map<String, String> cameFrom, String current) {
    final path = <String>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }

  /// Calculate heuristic distance (Euclidean) between two nodes
  double _heuristic(String nodeA, String nodeB, MallConfig mallConfig) {
    final posA = mallConfig.graphNodes[nodeA];
    final posB = mallConfig.graphNodes[nodeB];

    if (posA == null || posB == null) return double.infinity;

    return posA.distanceTo(posB);
  }

  /// Get actual distance between two connected nodes
  double _getDistance(String nodeA, String nodeB, MallConfig mallConfig) {
    final posA = mallConfig.graphNodes[nodeA];
    final posB = mallConfig.graphNodes[nodeB];

    if (posA == null || posB == null) return double.infinity;

    return posA.distanceTo(posB);
  }

  /// Find nearest graph node to a given point
  String? _findNearestNode(MapPoint point, MallConfig mallConfig) {
    String? nearestNode;
    double minDistance = double.infinity;

    for (final entry in mallConfig.graphNodes.entries) {
      final distance = point.distanceTo(entry.value);
      if (distance < minDistance) {
        minDistance = distance;
        nearestNode = entry.key;
      }
    }

    return nearestNode;
  }

  /// Smooth path to remove unnecessary waypoints
  List<MapPoint> _smoothPath(List<MapPoint> path) {
    if (path.length <= 2) return path;

    final smoothed = <MapPoint>[path.first];

    for (int i = 1; i < path.length - 1; i++) {
      final prev = smoothed.last;
      final current = path[i];
      final next = path[i + 1];

      // Check if we can skip the current point (line of sight)
      if (!_hasLineOfSight(prev, next)) {
        smoothed.add(current);
      }
    }

    smoothed.add(path.last);
    return smoothed;
  }

  /// Check if there's a clear line of sight between two points
  bool _hasLineOfSight(MapPoint from, MapPoint to) {
    // Simplified line of sight check
    // In a real implementation, you'd check for obstacles/walls
    const maxDirectDistance = 50.0; // Maximum direct connection distance
    return from.distanceTo(to) <= maxDirectDistance;
  }

  /// Calculate total path distance
  double calculatePathDistance(List<MapPoint> path) {
    if (path.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < path.length; i++) {
      totalDistance += path[i - 1].distanceTo(path[i]);
    }
    return totalDistance;
  }

  /// Estimate travel time in minutes
  double estimateTravelTime(List<MapPoint> path,
      {double walkingSpeedMPS = 1.4}) {
    final distanceMeters = calculatePathDistance(path);
    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) return 0.0;

    // Convert from map units to meters
    final actualDistance = distanceMeters / mallConfig.pixelToMeterRatio;

    // Calculate time in minutes
    return (actualDistance / walkingSpeedMPS) / 60.0;
  }

  /// Get turn-by-turn directions
  List<String> getDirections(List<MapPoint> path) {
    if (path.length < 2) return ['You have arrived at your destination.'];

    final directions = <String>[];

    if (path.length == 2) {
      directions.add('Head directly to your destination.');
    } else {
      directions.add('Start walking towards the first waypoint.');

      for (int i = 1; i < path.length - 1; i++) {
        final current = path[i - 1];
        final waypoint = path[i];
        final next = path[i + 1];

        final direction = _getDirection(current, waypoint, next);
        directions.add(direction);
      }
    }

    directions.add('You have arrived at your destination.');
    return directions;
  }

  /// Get direction instruction for a waypoint
  String _getDirection(MapPoint from, MapPoint current, MapPoint to) {
    final angle1 = math.atan2(current.y - from.y, current.x - from.x);
    final angle2 = math.atan2(to.y - current.y, to.x - current.x);

    var angleDiff = angle2 - angle1;

    // Normalize angle to [-π, π]
    while (angleDiff > math.pi) angleDiff -= 2 * math.pi;
    while (angleDiff < -math.pi) angleDiff += 2 * math.pi;

    final degrees = angleDiff * 180 / math.pi;

    if (degrees.abs() < 15) {
      return 'Continue straight';
    } else if (degrees > 15 && degrees < 75) {
      return 'Turn slightly right';
    } else if (degrees >= 75 && degrees <= 105) {
      return 'Turn right';
    } else if (degrees > 105) {
      return 'Turn sharp right';
    } else if (degrees < -15 && degrees > -75) {
      return 'Turn slightly left';
    } else if (degrees <= -75 && degrees >= -105) {
      return 'Turn left';
    } else {
      return 'Turn sharp left';
    }
  }
}

/// Priority queue implementation for A* algorithm
class PriorityQueue<T> {
  final List<T> _items = [];
  final Comparator<T> _compare;

  PriorityQueue(this._compare);

  void add(T item) {
    _items.add(item);
    _items.sort(_compare);
  }

  T removeFirst() {
    return _items.removeAt(0);
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  bool any(bool Function(T) test) => _items.any(test);
}

/// Node class for A* algorithm
class _AStarNode {
  final String nodeId;
  final double fScore;

  _AStarNode(this.nodeId, this.fScore);
}
