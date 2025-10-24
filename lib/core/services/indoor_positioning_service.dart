import 'dart:async';
import 'dart:math' as math;
import '../models/positioning_models.dart';

/// Indoor positioning service using trilateration algorithm
class IndoorPositioningService {
  IndoorPositioningService._();
  static final instance = IndoorPositioningService._();

  final StreamController<Position?> _positionController =
      StreamController<Position?>.broadcast();

  Position? _lastKnownPosition;
  final Map<String, Beacon> _activeBeacons = {};

  // Configuration
  static const int minBeaconsForTrilateration = 3;
  static const double maxBeaconDistance = 15.0; // meters
  static const Duration beaconTimeout = Duration(seconds: 10);
  static const double positionSmoothingFactor = 0.3; // For position smoothing

  /// Stream of calculated positions
  Stream<Position?> get positionStream => _positionController.stream;

  /// Get current position
  Position? get currentPosition => _lastKnownPosition;

  /// Update beacon data for positioning calculation
  void updateBeacon(Beacon beacon) {
    // Only use beacons within reasonable range
    if (beacon.distance <= maxBeaconDistance && beacon.isFresh) {
      _activeBeacons[beacon.id] = beacon;
      _calculatePosition();
    }
  }

  /// Update multiple beacons at once
  void updateBeacons(List<Beacon> beacons) {
    for (final beacon in beacons) {
      updateBeacon(beacon);
    }
  }

  /// Remove stale beacons and recalculate position
  void cleanupStaleBeacons() {
    final now = DateTime.now();
    final staleBeacons = _activeBeacons.entries
        .where((entry) => now.difference(entry.value.lastSeen) > beaconTimeout)
        .map((entry) => entry.key)
        .toList();

    for (final beaconId in staleBeacons) {
      _activeBeacons.remove(beaconId);
    }

    if (staleBeacons.isNotEmpty) {
      _calculatePosition();
    }
  }

  /// Calculate position using trilateration algorithm
  void _calculatePosition() {
    cleanupStaleBeacons();

    final validBeacons = _activeBeacons.values
        .where((beacon) => beacon.distance <= maxBeaconDistance)
        .toList();

    if (validBeacons.length < minBeaconsForTrilateration) {
      // Not enough beacons for trilateration
      if (validBeacons.length == 1) {
        // Use single beacon with low accuracy
        final beacon = validBeacons.first;
        final position = Position(
          x: beacon.position.x,
          y: beacon.position.y,
          accuracy: beacon.distance,
          timestamp: DateTime.now(),
          floorLevel: beacon.position.floorLevel,
        );
        _updatePosition(position);
      } else if (validBeacons.length == 2) {
        // Use weighted average of two beacons
        final position = _calculateWeightedAverage(validBeacons);
        _updatePosition(position);
      }
      return;
    }

    // Use trilateration with multiple beacons
    final position = _trilaterate(validBeacons);
    if (position != null) {
      _updatePosition(position);
    }
  }

  /// Calculate weighted average position from 2 beacons
  Position _calculateWeightedAverage(List<Beacon> beacons) {
    assert(beacons.length == 2);

    final beacon1 = beacons[0];
    final beacon2 = beacons[1];

    // Weight by inverse distance (closer beacons have more influence)
    final weight1 = 1.0 /
        (beacon1.distance + 0.1); // Add small value to avoid division by zero
    final weight2 = 1.0 / (beacon2.distance + 0.1);
    final totalWeight = weight1 + weight2;

    final x = (beacon1.position.x * weight1 + beacon2.position.x * weight2) /
        totalWeight;
    final y = (beacon1.position.y * weight1 + beacon2.position.y * weight2) /
        totalWeight;

    final avgDistance = (beacon1.distance + beacon2.distance) / 2;

    return Position(
      x: x,
      y: y,
      accuracy: avgDistance,
      timestamp: DateTime.now(),
      floorLevel: beacon1.position.floorLevel,
    );
  }

  /// Trilateration algorithm using least squares method
  Position? _trilaterate(List<Beacon> beacons) {
    if (beacons.length < 3) return null;

    try {
      // Use first 3-4 beacons for trilateration (more can improve accuracy)
      final useBeacons = beacons.take(4).toList();

      // Set up matrices for least squares solution
      // We solve: A * [x, y] = b
      final n = useBeacons.length;
      final A = List.generate(n - 1, (_) => List.filled(2, 0.0));
      final b = List.filled(n - 1, 0.0);

      final x1 = useBeacons[0].position.x;
      final y1 = useBeacons[0].position.y;
      final r1 = useBeacons[0].distance;

      for (int i = 1; i < n; i++) {
        final xi = useBeacons[i].position.x;
        final yi = useBeacons[i].position.y;
        final ri = useBeacons[i].distance;

        A[i - 1][0] = 2 * (xi - x1);
        A[i - 1][1] = 2 * (yi - y1);
        b[i - 1] =
            (xi * xi - x1 * x1) + (yi * yi - y1 * y1) - (ri * ri - r1 * r1);
      }

      // Solve using pseudo-inverse (simplified for 2D case)
      final solution = _solveLeastSquares(A, b);
      if (solution == null) return null;

      final calculatedX = solution[0];
      final calculatedY = solution[1];

      // Calculate accuracy as average distance error
      double totalError = 0.0;
      for (final beacon in useBeacons) {
        final expectedDistance = math.sqrt(
            math.pow(calculatedX - beacon.position.x, 2) +
                math.pow(calculatedY - beacon.position.y, 2));
        totalError += (expectedDistance - beacon.distance).abs();
      }
      final accuracy = totalError / useBeacons.length;

      return Position(
        x: calculatedX,
        y: calculatedY,
        accuracy: accuracy,
        timestamp: DateTime.now(),
        floorLevel: useBeacons.first.position.floorLevel,
      );
    } catch (e) {
      print('Trilateration error: $e');
      return null;
    }
  }

  /// Solve least squares problem A * x = b
  List<double>? _solveLeastSquares(List<List<double>> A, List<double> b) {
    try {
      // For 2D case, we can use direct solution
      if (A.length >= 2 && A[0].length == 2) {
        // Use normal equations: (A^T * A) * x = A^T * b
        final AtA = _multiplyTranspose(A, A);
        final Atb = _multiplyTransposeVector(A, b);

        // Solve 2x2 system
        final det = AtA[0][0] * AtA[1][1] - AtA[0][1] * AtA[1][0];
        if (det.abs() < 1e-10) return null; // Singular matrix

        final x = (AtA[1][1] * Atb[0] - AtA[0][1] * Atb[1]) / det;
        final y = (AtA[0][0] * Atb[1] - AtA[1][0] * Atb[0]) / det;

        return [x, y];
      }
      return null;
    } catch (e) {
      print('Least squares solver error: $e');
      return null;
    }
  }

  /// Matrix multiplication A^T * A
  List<List<double>> _multiplyTranspose(
      List<List<double>> A, List<List<double>> B) {
    final rows = A[0].length;
    final cols = B[0].length;
    final result = List.generate(rows, (_) => List.filled(cols, 0.0));

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < A.length; k++) {
          result[i][j] += A[k][i] * B[k][j];
        }
      }
    }
    return result;
  }

  /// Matrix-vector multiplication A^T * b
  List<double> _multiplyTransposeVector(List<List<double>> A, List<double> b) {
    final result = List.filled(A[0].length, 0.0);
    for (int i = 0; i < A[0].length; i++) {
      for (int j = 0; j < A.length; j++) {
        result[i] += A[j][i] * b[j];
      }
    }
    return result;
  }

  /// Update position with smoothing
  void _updatePosition(Position newPosition) {
    if (_lastKnownPosition == null) {
      _lastKnownPosition = newPosition;
    } else {
      // Apply exponential smoothing
      final smoothedX = _lastKnownPosition!.x * (1 - positionSmoothingFactor) +
          newPosition.x * positionSmoothingFactor;
      final smoothedY = _lastKnownPosition!.y * (1 - positionSmoothingFactor) +
          newPosition.y * positionSmoothingFactor;

      _lastKnownPosition = Position(
        x: smoothedX,
        y: smoothedY,
        accuracy: newPosition.accuracy,
        timestamp: newPosition.timestamp,
        floorLevel: newPosition.floorLevel,
      );
    }

    _positionController.add(_lastKnownPosition);
  }

  /// Reset positioning system
  void reset() {
    _activeBeacons.clear();
    _lastKnownPosition = null;
    _positionController.add(null);
  }

  /// Get debug info about active beacons
  Map<String, dynamic> getDebugInfo() {
    return {
      'active_beacons': _activeBeacons.length,
      'beacon_details': _activeBeacons.values
          .map((b) => {
                'id': b.id,
                'distance': b.distance.toStringAsFixed(2),
                'rssi': b.rssi,
                'position': '(${b.position.x}, ${b.position.y})'
              })
          .toList(),
      'current_position': _lastKnownPosition?.toString(),
      'can_trilaterate': _activeBeacons.length >= minBeaconsForTrilateration,
    };
  }

  /// Dispose resources
  void dispose() {
    _positionController.close();
    _activeBeacons.clear();
  }
}
