import 'package:flutter_test/flutter_test.dart';
import 'package:future_shopping2/core/services/mall_navigation_example_service.dart';
import 'package:future_shopping2/core/services/mall_data_service.dart';
import 'package:future_shopping2/core/services/indoor_positioning_service.dart';
import 'package:future_shopping2/core/services/navigation_mode_manager.dart';

void main() {
  group('Mall Navigation System Tests', () {
    late MallNavigationExampleService navigationService;

    setUpAll(() async {
      navigationService = MallNavigationExampleService.instance;
    });

    tearDownAll(() {
      navigationService.dispose();
    });

    test('Should initialize mall navigation system successfully', () async {
      // Test initialization
      final result = await navigationService.initializeAll();
      expect(result, isTrue);

      // Verify mall data is loaded
      final mallConfig = MallDataService.instance.mallConfig;
      expect(mallConfig, isNotNull);
      expect(mallConfig!.name, equals('Sample Mall for Testing'));
      expect(mallConfig.beacons.length, equals(5));
      expect(mallConfig.stores.length, equals(3));
    });

    test('Should simulate beacon detection and calculate position', () async {
      await navigationService.initializeAll();

      // Simulate multiple beacons
      navigationService.simulateBeaconDetection(101, -65); // Close beacon
      navigationService.simulateBeaconDetection(102, -75); // Medium distance
      navigationService.simulateBeaconDetection(103, -85); // Far beacon

      // Wait for positioning to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if position was calculated
      final position = IndoorPositioningService.instance.currentPosition;
      expect(position, isNotNull);
      expect(position!.x, greaterThan(0));
      expect(position.y, greaterThan(0));
      expect(position.accuracy, lessThan(50)); // Reasonable accuracy
    });

    test('Should navigate to a store successfully', () async {
      await navigationService.initializeAll();

      // First establish position
      navigationService.simulateBeaconDetection(101, -65);
      navigationService.simulateBeaconDetection(102, -75);
      navigationService.simulateBeaconDetection(103, -85);

      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to Starbucks
      final result = await navigationService.navigateToStore('store_003');
      expect(result, isTrue);

      // Check navigation state
      final targetStore = NavigationModeManager.instance.targetStore;
      expect(targetStore, isNotNull);
      expect(targetStore!.name, equals('Starbucks'));

      final currentPath = NavigationModeManager.instance.currentPath;
      expect(currentPath, isNotNull);
      expect(currentPath!.length, greaterThan(1));
    });

    test('Should search for stores correctly', () async {
      await navigationService.initializeAll();

      // Search by name
      final starbucks = navigationService.searchStores('Starbucks');
      expect(starbucks.length, equals(1));
      expect(starbucks.first.name, equals('Starbucks'));

      // Search by category
      final electronics = navigationService.getStoresByCategory('Electronics');
      expect(electronics.length, equals(1));
      expect(electronics.first.name, equals('Apple Store'));

      // Search all stores
      final allStores = navigationService.searchStores('');
      expect(allStores.length, equals(3));
    });

    test('Should provide system status information', () async {
      await navigationService.initializeAll();

      final status = navigationService.getSystemStatus();
      expect(status['initialized'], isTrue);
      expect(status['mall_config']['loaded'], isTrue);
      expect(status['mall_config']['beacons_count'], equals(5));
      expect(status['mall_config']['stores_count'], equals(3));
    });

    test('Should handle navigation mode switching', () async {
      await navigationService.initializeAll();

      // Start with mall navigation mode
      expect(NavigationModeManager.instance.currentMode,
          equals(NavigationMode.mallNavigation));

      // Simulate entering a store (Apple Store area)
      // Position inside Apple Store polygon (45-60, 45-60)

      // Create mock position inside Apple Store
      // Note: This is a simplified test - in reality the position
      // would be calculated from beacon triangulation

      expect(NavigationModeManager.instance.currentStore, isNull);
    });
  });
}
