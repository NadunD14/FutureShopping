# Mall Navigation Refactoring Plan

## 1. New Flutter Packages Required

### Core Navigation & Mapping
```yaml
dependencies:
  # Current packages (keep these)
  flutter_blue_plus: ^1.31.7
  permission_handler: ^11.0.1
  
  # NEW PACKAGES FOR MALL NAVIGATION:
  
  # 2D Map Rendering
  flutter_map: ^6.1.0           # Leaflet-based mapping solution
  latlong2: ^0.8.1              # For coordinate calculations
  
  # Indoor Positioning & Algorithms
  ml_linalg: ^13.16.0           # Linear algebra for trilateration
  collection: ^1.17.2           # Enhanced collections for algorithms
  
  # Pathfinding & Graph Algorithms
  graphs: ^2.3.1                # Graph data structures and A* pathfinding
  
  # Vector Math & Geometry
  vector_math: ^2.1.4           # Vector operations for positioning
  
  # Data Storage & Caching
  sqflite: ^2.3.0               # Local database for mall data
  shared_preferences: ^2.2.2    # Store user preferences
  
  # Map Overlays & Custom Widgets
  flutter_svg: ^2.0.9           # SVG support for custom map icons
  
  # Performance & Smoothing
  flutter_animate: ^4.2.0       # Smooth animations for position updates
```

## 2. Data Structure for Mall Map

### Recommended Approach: JSON + SQLite Hybrid

**Why this approach:**
- JSON for initial data loading and configuration
- SQLite for runtime queries (nearest beacons, pathfinding)
- Easy to update mall layouts without app releases

### Mall Data Structure Example:
```json
{
  "mall_config": {
    "id": "westfield_mall_01",
    "name": "Westfield Shopping Mall",
    "bounds": {
      "min_x": 0,
      "min_y": 0,
      "max_x": 500,
      "max_y": 300
    },
    "pixel_to_meter_ratio": 10
  },
  "beacons": [
    {
      "id": "beacon_001",
      "uuid": "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0",
      "major": 1,
      "minor": 101,
      "position": {"x": 50, "y": 50},
      "tx_power": -59,
      "floor_level": 1
    }
  ],
  "stores": [
    {
      "id": "store_001",
      "name": "Apple Store",
      "category": "Electronics",
      "polygon": [
        {"x": 45, "y": 45},
        {"x": 65, "y": 45},
        {"x": 65, "y": 65},
        {"x": 45, "y": 65}
      ],
      "entrance_point": {"x": 55, "y": 45},
      "associated_beacons": ["beacon_001"],
      "floor_level": 1
    }
  ],
  "walkable_paths": [
    {
      "id": "path_001",
      "nodes": [
        {"x": 50, "y": 30},
        {"x": 100, "y": 30},
        {"x": 100, "y": 80}
      ],
      "width": 5,
      "floor_level": 1
    }
  ],
  "pathfinding_graph": {
    "nodes": [
      {"id": "n1", "x": 50, "y": 30},
      {"id": "n2", "x": 100, "y": 30}
    ],
    "edges": [
      {"from": "n1", "to": "n2", "cost": 50}
    ]
  }
}
```

## 3. High-Level Refactoring Plan for Beacon Service

### Current Architecture (Single Beacon)
```
BleService -> Single Beacon Detection -> Proximity Zones -> Product List
```

### New Architecture (Multi-Beacon Mall Navigation)
```
MallBleService -> Multiple Beacon Detection -> IndoorPositioningService -> NavigationModeManager
    ↓                                             ↓                           ↓
All Beacons                                 Trilateration                Hybrid Mode Switch
    ↓                                             ↓                           ↓
RSSI + TxPower                              Position (x,y)              Mall Nav / Store Mode
```

### Key Changes:

1. **MallBleService**: Replaces your current `BleService`
   - Scans for ALL beacons simultaneously
   - Maps detected beacons to mall configuration
   - Feeds beacon data to positioning service

2. **IndoorPositioningService**: New positioning engine
   - Uses trilateration algorithm with 3+ beacons
   - Fallback to weighted average with 2 beacons
   - Position smoothing and accuracy estimation

3. **NavigationModeManager**: Hybrid mode controller
   - Monitors user position vs store polygons
   - Switches between mall navigation and store mode
   - Manages pathfinding and turn-by-turn directions

4. **MallDataService**: Configuration management
   - Loads mall layout from JSON
   - Provides store search and categorization
   - Beacon-to-position mapping

## 4. Conceptual Code Example for Core Positioning Logic

```dart
// Core positioning function
Position? calculatePosition(List<Beacon> beacons) {
  final validBeacons = beacons
      .where((b) => b.distance <= 15.0 && b.isFresh)
      .toList();

  if (validBeacons.length >= 3) {
    // Use trilateration with 3+ beacons
    return _trilaterate(validBeacons);
  } else if (validBeacons.length == 2) {
    // Use weighted average with 2 beacons
    return _calculateWeightedAverage(validBeacons);
  } else if (validBeacons.length == 1) {
    // Single beacon - low accuracy
    final beacon = validBeacons.first;
    return Position(
      x: beacon.position.x,
      y: beacon.position.y,
      accuracy: beacon.distance,
      timestamp: DateTime.now(),
    );
  }
  
  return null; // No valid beacons
}

// Trilateration implementation
Position? _trilaterate(List<Beacon> beacons) {
  // Set up least squares matrices
  final n = beacons.length;
  final A = List.generate(n - 1, (_) => List.filled(2, 0.0));
  final b = List.filled(n - 1, 0.0);

  final x1 = beacons[0].position.x;
  final y1 = beacons[0].position.y;
  final r1 = beacons[0].distance;

  for (int i = 1; i < n; i++) {
    final xi = beacons[i].position.x;
    final yi = beacons[i].position.y;
    final ri = beacons[i].distance;

    A[i - 1][0] = 2 * (xi - x1);
    A[i - 1][1] = 2 * (yi - y1);
    b[i - 1] = (xi * xi - x1 * x1) + (yi * yi - y1 * y1) - 
               (ri * ri - r1 * r1);
  }

  // Solve using pseudo-inverse
  final solution = _solveLeastSquares(A, b);
  if (solution == null) return null;

  return Position(
    x: solution[0],
    y: solution[1],
    accuracy: _calculateAccuracy(beacons, solution),
    timestamp: DateTime.now(),
  );
}
```

## 5. Implementing Hybrid Mode

### Store Detection Logic:
```dart
void _checkStoreProximity(Position position) {
  final mallConfig = MallDataService.instance.mallConfig;
  
  for (final store in mallConfig.stores) {
    // Check if inside store polygon
    if (store.containsPosition(position)) {
      _scheduleStoreEntry(store);
      return;
    }
  }
  
  // If not in any store, stay in mall navigation mode
  if (_currentStore != null) {
    _scheduleStoreExit();
  }
}

bool _isInsidePolygon(Position position, List<MapPoint> polygon) {
  bool inside = false;
  int j = polygon.length - 1;
  
  for (int i = 0; i < polygon.length; i++) {
    final xi = polygon[i].x, yi = polygon[i].y;
    final xj = polygon[j].x, yj = polygon[j].y;
    
    if (((yi > position.y) != (yj > position.y)) &&
        (position.x < (xj - xi) * (position.y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }
  
  return inside;
}
```

### Mode Switching:
```dart
enum NavigationMode {
  mallNavigation,  // Show map, pathfinding, blue dot
  storeMode,       // Show products for current store
  transitioning,   // Brief transition state
}

void _enterStoreMode(Store store) {
  print('Entering store mode for: ${store.name}');
  
  _currentStore = store;
  _clearNavigation(); // Stop pathfinding
  _setMode(NavigationMode.storeMode);
  
  // Trigger your existing product list logic here
  _loadProductsForStore(store);
}

void _exitStoreMode() {
  print('Exiting store mode, returning to mall navigation');
  
  _currentStore = null;
  _setMode(NavigationMode.mallNavigation);
  
  // Return to map view
  _showMallMap();
}
```

## 6. Integration Steps

### Step 1: Add new packages to pubspec.yaml
```yaml
dependencies:
  # Add the packages listed in section 1
```

### Step 2: Create the new services
- `lib/core/models/positioning_models.dart` - Data models
- `lib/core/services/mall_data_service.dart` - Configuration management
- `lib/core/services/indoor_positioning_service.dart` - Positioning engine
- `lib/core/services/mall_ble_service.dart` - Multi-beacon scanning
- `lib/core/services/pathfinding_service.dart` - A* pathfinding
- `lib/core/services/navigation_mode_manager.dart` - Hybrid mode controller

### Step 3: Create mall configuration
- `assets/mall_config.json` - Mall layout and beacon positions

### Step 4: Initialize the system
```dart
// In your main app initialization
Future<void> initializeMallNavigation() async {
  // Load mall configuration
  await MallDataService.instance.initialize();
  
  // Initialize positioning
  await IndoorPositioningService.instance.reset();
  
  // Start navigation manager
  await NavigationModeManager.instance.initialize();
  
  // Start BLE scanning
  await MallBleService.instance.startScanning();
}
```

### Step 5: Update your UI
- Mall navigation view: Map with blue dot and pathfinding
- Store mode view: Your existing product list
- Search and navigation controls

## 7. Testing Strategy

### Phase 1: Positioning Testing
```dart
// Test with simulated beacons
void testPositioning() {
  MallNavigationExampleService.instance.simulateBeaconDetection(101, -65);
  MallNavigationExampleService.instance.simulateBeaconDetection(102, -75);
  MallNavigationExampleService.instance.simulateBeaconDetection(103, -85);
}
```

### Phase 2: Navigation Testing
```dart
// Test pathfinding
void testNavigation() {
  NavigationModeManager.instance.navigateToStore('store_003');
}
```

### Phase 3: Hybrid Mode Testing
- Walk around with physical beacons
- Verify mode switching when entering/exiting stores
- Test product list integration

## 8. Migration Path from Current App

1. **Keep your existing BleService for now** - Run both systems in parallel
2. **Migrate gradually** - Start with positioning, then pathfinding, then hybrid mode
3. **Reuse your product logic** - Your current proximity-based product recommendations can be called from store mode
4. **Update gradually** - Replace old beacon service once new system is stable

This architecture gives you a professional indoor navigation solution while preserving your existing product recommendation functionality!