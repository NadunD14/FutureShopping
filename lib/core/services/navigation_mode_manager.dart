import 'dart:async';
import '../models/positioning_models.dart';
import 'mall_data_service.dart';
import 'indoor_positioning_service.dart';
import 'pathfinding_service.dart';

/// Navigation modes for the app
enum NavigationMode {
  /// Mall-wide navigation with map view
  mallNavigation,

  /// Store-specific mode with product recommendations
  storeMode,

  /// Transitioning between modes
  transitioning,
}

/// Hybrid navigation manager that switches between mall navigation and store mode
class NavigationModeManager {
  NavigationModeManager._();
  static final instance = NavigationModeManager._();

  final StreamController<NavigationMode> _modeController =
      StreamController<NavigationMode>.broadcast();
  final StreamController<Store?> _currentStoreController =
      StreamController<Store?>.broadcast();
  final StreamController<List<MapPoint>?> _currentPathController =
      StreamController<List<MapPoint>?>.broadcast();

  NavigationMode _currentMode = NavigationMode.mallNavigation;
  Store? _currentStore;
  Store? _targetStore;
  List<MapPoint>? _currentPath;
  Position? _lastPosition;

  StreamSubscription<Position?>? _positionSubscription;
  Timer? _modeCheckTimer;

  // Configuration
  static const Duration storeEntryDelay = Duration(seconds: 3);
  static const Duration storeExitDelay = Duration(seconds: 5);
  static const double storeProximityThreshold = 5.0; // meters

  /// Stream of navigation mode changes
  Stream<NavigationMode> get modeStream => _modeController.stream;

  /// Stream of current store changes
  Stream<Store?> get currentStoreStream => _currentStoreController.stream;

  /// Stream of current navigation path
  Stream<List<MapPoint>?> get currentPathStream =>
      _currentPathController.stream;

  /// Current navigation mode
  NavigationMode get currentMode => _currentMode;

  /// Current store (if in store mode)
  Store? get currentStore => _currentStore;

  /// Target store for navigation
  Store? get targetStore => _targetStore;

  /// Current navigation path
  List<MapPoint>? get currentPath => _currentPath;

  /// Initialize the navigation manager
  Future<void> initialize() async {
    print('Initializing NavigationModeManager...');

    // Listen to position updates
    _positionSubscription =
        IndoorPositioningService.instance.positionStream.listen(
      _onPositionUpdate,
      onError: (error) => print('Position stream error: $error'),
    );

    // Start periodic mode checking
    _modeCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkModeTransition();
    });

    print('NavigationModeManager initialized');
  }

  /// Handle position updates
  void _onPositionUpdate(Position? position) {
    if (position == null) return;

    _lastPosition = position;
    _checkStoreProximity(position);
  }

  /// Check if user is near or inside a store
  void _checkStoreProximity(Position position) {
    final mallConfig = MallDataService.instance.mallConfig;
    if (mallConfig == null) return;

    Store? containingStore;
    Store? nearbyStore;
    double minDistance = double.infinity;

    for (final store in mallConfig.stores) {
      // Check if inside store polygon
      if (store.containsPosition(position)) {
        containingStore = store;
        break;
      }

      // Check proximity to store entrance
      final distance = position.distanceTo(Position(
        x: store.entrancePoint.x,
        y: store.entrancePoint.y,
        accuracy: 0,
        timestamp: DateTime.now(),
        floorLevel: store.floorLevel,
      ));

      if (distance < storeProximityThreshold && distance < minDistance) {
        minDistance = distance;
        nearbyStore = store;
      }
    }

    // Prioritize containing store over nearby store
    final detectedStore = containingStore ?? nearbyStore;

    if (detectedStore != _currentStore) {
      _handleStoreChange(detectedStore);
    }
  }

  /// Handle store change detection
  void _handleStoreChange(Store? newStore) {
    if (newStore == null) {
      // Exiting store
      if (_currentStore != null) {
        print('Exiting store: ${_currentStore!.name}');
        _scheduleStoreExit();
      }
    } else {
      // Entering store
      if (_currentStore != newStore) {
        print('Entering store: ${newStore.name}');
        _scheduleStoreEntry(newStore);
      }
    }
  }

  /// Schedule store entry after delay
  void _scheduleStoreEntry(Store store) {
    _setMode(NavigationMode.transitioning);

    Timer(storeEntryDelay, () {
      // Verify user is still in store
      if (_lastPosition != null && store.containsPosition(_lastPosition!)) {
        _enterStoreMode(store);
      } else {
        _setMode(NavigationMode.mallNavigation);
      }
    });
  }

  /// Schedule store exit after delay
  void _scheduleStoreExit() {
    Timer(storeExitDelay, () {
      // Verify user is still outside store
      if (_currentStore != null &&
          _lastPosition != null &&
          !_currentStore!.containsPosition(_lastPosition!)) {
        _exitStoreMode();
      }
    });
  }

  /// Enter store mode
  void _enterStoreMode(Store store) {
    print('Entering store mode for: ${store.name}');

    _currentStore = store;
    _currentStoreController.add(store);

    // Clear navigation path when entering store
    _clearNavigation();

    _setMode(NavigationMode.storeMode);
  }

  /// Exit store mode
  void _exitStoreMode() {
    print('Exiting store mode, returning to mall navigation');

    _currentStore = null;
    _currentStoreController.add(null);

    _setMode(NavigationMode.mallNavigation);
  }

  /// Set navigation target and calculate path
  Future<bool> navigateToStore(Store targetStore) async {
    if (_lastPosition == null) {
      print('Cannot navigate: current position unknown');
      return false;
    }

    print('Navigating to store: ${targetStore.name}');

    _targetStore = targetStore;

    // Calculate path to target store
    final path =
        PathfindingService.instance.findPath(_lastPosition!, targetStore);

    if (path == null) {
      print('Failed to find path to ${targetStore.name}');
      return false;
    }

    _currentPath = path;
    _currentPathController.add(path);

    // Switch to mall navigation mode if not already
    if (_currentMode != NavigationMode.mallNavigation) {
      _setMode(NavigationMode.mallNavigation);
    }

    print('Navigation path calculated: ${path.length} waypoints');
    return true;
  }

  /// Clear current navigation
  void clearNavigation() {
    print('Clearing navigation');
    _clearNavigation();
  }

  void _clearNavigation() {
    _targetStore = null;
    _currentPath = null;
    _currentPathController.add(null);
  }

  /// Force mode change (for manual control)
  void setMode(NavigationMode mode) {
    print('Manually setting mode to: $mode');
    _setMode(mode);
  }

  void _setMode(NavigationMode mode) {
    if (_currentMode != mode) {
      print('Mode changed: $_currentMode -> $mode');
      _currentMode = mode;
      _modeController.add(mode);
    }
  }

  /// Check for automatic mode transitions
  void _checkModeTransition() {
    if (_lastPosition == null) return;

    // Auto-clear navigation if user reached target
    if (_targetStore != null && _currentPath != null) {
      final distanceToTarget = _lastPosition!.distanceTo(Position(
        x: _targetStore!.entrancePoint.x,
        y: _targetStore!.entrancePoint.y,
        accuracy: 0,
        timestamp: DateTime.now(),
        floorLevel: _targetStore!.floorLevel,
      ));

      if (distanceToTarget < 3.0) {
        // Within 3 meters of target
        print('Reached navigation target: ${_targetStore!.name}');
        _clearNavigation();
      }
    }
  }

  /// Get current mode information
  Map<String, dynamic> getCurrentModeInfo() {
    return {
      'mode': _currentMode.toString(),
      'current_store': _currentStore?.name,
      'target_store': _targetStore?.name,
      'has_path': _currentPath != null,
      'path_waypoints': _currentPath?.length ?? 0,
      'last_position': _lastPosition?.toString(),
    };
  }

  /// Search for stores and provide navigation options
  List<Store> searchStores(String query) {
    return MallDataService.instance.searchStores(query);
  }

  /// Get stores by category
  List<Store> getStoresByCategory(String category) {
    return MallDataService.instance.getStoresByCategory(category);
  }

  /// Get available store categories
  List<String> getCategories() {
    return MallDataService.instance.getCategories();
  }

  /// Dispose resources
  void dispose() {
    print('Disposing NavigationModeManager...');

    _positionSubscription?.cancel();
    _modeCheckTimer?.cancel();

    _modeController.close();
    _currentStoreController.close();
    _currentPathController.close();
  }
}
