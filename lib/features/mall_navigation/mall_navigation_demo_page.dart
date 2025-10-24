import 'package:flutter/material.dart' hide NavigationMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/positioning_models.dart';
import '../../core/services/mall_navigation_example_service.dart';
import '../../core/services/navigation_mode_manager.dart';

/// Example UI showing how to use the mall navigation system
class MallNavigationDemoPage extends ConsumerWidget {
  const MallNavigationDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(mallNavigationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mall Navigation Demo'),
        backgroundColor: _getModeColor(navigationState.mode),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showSystemStatus(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          _buildStatusBar(navigationState),

          // Main Content
          Expanded(
            child: _buildMainContent(context, ref, navigationState),
          ),

          // Control Panel
          _buildControlPanel(context, ref, navigationState),
        ],
      ),
    );
  }

  Widget _buildStatusBar(MallNavigationState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: _getModeColor(state.mode).withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getModeIcon(state.mode),
                color: _getModeColor(state.mode),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mode: ${_getModeDisplayName(state.mode)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getModeColor(state.mode),
                ),
              ),
            ],
          ),
          if (state.currentPosition != null) ...[
            const SizedBox(height: 4),
            Text(
              'Position: (${state.currentPosition!.x.toStringAsFixed(1)}, ${state.currentPosition!.y.toStringAsFixed(1)}) ±${state.currentPosition!.accuracy.toStringAsFixed(1)}m',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (state.currentStore != null) ...[
            const SizedBox(height: 4),
            Text(
              'In Store: ${state.currentStore!.name}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
          if (state.targetStore != null) ...[
            const SizedBox(height: 4),
            Text(
              'Navigating to: ${state.targetStore!.name}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, WidgetRef ref, MallNavigationState state) {
    switch (state.mode) {
      case NavigationMode.storeMode:
        return _buildStoreMode(state.currentStore);
      case NavigationMode.mallNavigation:
        return _buildMallNavigationMode(state);
      case NavigationMode.transitioning:
        return _buildTransitioningMode();
    }
  }

  Widget _buildStoreMode(Store? store) {
    if (store == null) return const Center(child: Text('No store selected'));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to ${store.name}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Category: ${store.category}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'Product Recommendations:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          // This is where you'd integrate your existing product list logic
          Expanded(
            child: _buildProductList(store),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(Store store) {
    // Placeholder for your existing product recommendation logic
    final products = _getMockProducts(store.category);

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text('${index + 1}'),
            ),
            title: Text(product['name'] as String),
            subtitle: Text('\$${product['price']}'),
            trailing: const Icon(Icons.add_shopping_cart),
            onTap: () {
              // Handle product selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${product['name']} to cart')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMallNavigationMode(MallNavigationState state) {
    return Column(
      children: [
        // Map placeholder (you'd integrate flutter_map here)
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Text(
                    '🗺️ Mall Map\n(Integrate flutter_map here)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                if (state.currentPosition != null)
                  Positioned(
                    left: state.currentPosition!.x * 2, // Scale for demo
                    top: state.currentPosition!.y * 1.5, // Scale for demo
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Store search and navigation
        Expanded(
          child: _buildStoreSearch(),
        ),
      ],
    );
  }

  Widget _buildStoreSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find a Store:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final stores =
                    MallNavigationExampleService.instance.searchStores('');

                return ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(store.category),
                          child: Text(
                            store.name.substring(0, 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(store.name),
                        subtitle: Text(store.category),
                        trailing: const Icon(Icons.navigation),
                        onTap: () {
                          ref
                              .read(mallNavigationProvider.notifier)
                              .navigateToStore(store.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Navigating to ${store.name}')),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitioningMode() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Switching modes...'),
        ],
      ),
    );
  }

  Widget _buildControlPanel(
      BuildContext context, WidgetRef ref, MallNavigationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!state.isInitialized) ...[
            ElevatedButton(
              onPressed: () =>
                  ref.read(mallNavigationProvider.notifier).initialize(),
              child: const Text('Initialize System'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(mallNavigationProvider.notifier)
                        .startNavigation(),
                    child: const Text('Start Navigation'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(mallNavigationProvider.notifier)
                        .stopNavigation(),
                    child: const Text('Stop Navigation'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _simulateBeacons(ref),
                    child: const Text('Simulate Beacons'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(mallNavigationProvider.notifier)
                        .clearNavigation(),
                    child: const Text('Clear Navigation'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _simulateBeacons(WidgetRef ref) {
    // Simulate multiple beacons for testing
    ref.read(mallNavigationProvider.notifier).simulateBeacon(101, -65);
    ref.read(mallNavigationProvider.notifier).simulateBeacon(102, -75);
    ref.read(mallNavigationProvider.notifier).simulateBeacon(103, -85);
  }

  void _showSystemStatus(BuildContext context) {
    final status = MallNavigationExampleService.instance.getSystemStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Status'),
        content: SingleChildScrollView(
          child: Text(
            status.entries.map((e) => '${e.key}: ${e.value}').join('\n\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.mallNavigation:
        return Colors.blue;
      case NavigationMode.storeMode:
        return Colors.green;
      case NavigationMode.transitioning:
        return Colors.orange;
    }
  }

  IconData _getModeIcon(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.mallNavigation:
        return Icons.map;
      case NavigationMode.storeMode:
        return Icons.store;
      case NavigationMode.transitioning:
        return Icons.sync;
    }
  }

  String _getModeDisplayName(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.mallNavigation:
        return 'Mall Navigation';
      case NavigationMode.storeMode:
        return 'Store Mode';
      case NavigationMode.transitioning:
        return 'Transitioning';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Colors.blue;
      case 'fashion':
        return Colors.purple;
      case 'food & beverage':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getMockProducts(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return [
          {'name': 'iPhone 15 Pro', 'price': '999'},
          {'name': 'MacBook Air M2', 'price': '1299'},
          {'name': 'AirPods Pro', 'price': '249'},
          {'name': 'Apple Watch Series 9', 'price': '399'},
        ];
      case 'fashion':
        return [
          {'name': 'Nike Air Force 1', 'price': '90'},
          {'name': 'Adidas Ultraboost', 'price': '180'},
          {'name': 'Running Shorts', 'price': '35'},
          {'name': 'Sports T-Shirt', 'price': '25'},
        ];
      case 'food & beverage':
        return [
          {'name': 'Caffe Latte', 'price': '4.50'},
          {'name': 'Frappuccino', 'price': '5.25'},
          {'name': 'Croissant', 'price': '3.50'},
          {'name': 'Protein Box', 'price': '8.95'},
        ];
      default:
        return [
          {'name': 'Sample Product 1', 'price': '19.99'},
          {'name': 'Sample Product 2', 'price': '29.99'},
          {'name': 'Sample Product 3', 'price': '39.99'},
        ];
    }
  }
}
