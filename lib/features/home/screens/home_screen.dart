import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_data_seeder.dart';
import '../../../core/models/product_model.dart';
import '../../product/providers/product_provider.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../comparison/screens/comparison_screen.dart';
import '../../shopping_list/screens/shopping_list_screen.dart';
import '../../mall_navigation/mall_navigation_demo_page.dart';

/// Home screen - main welcome screen of the app
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Ensure Firebase has sample data for testing
    // Seed two shops with 10+ items each
    await FirebaseDataSeeder.seedTwoShopsData();

    // Start BLE scanning
    _startBeaconScanning();
  }

  Future<void> _startBeaconScanning() async {
    // Start scanning via provider
    ref.read(bleScanningStateProvider.notifier).startScanning();
  }

  @override
  void dispose() {
    // Stop scanning via provider
    ref.read(bleScanningStateProvider.notifier).stopScanning();
    super.dispose();
  }

  // Notifications disabled per requirement

  Widget _buildNearbyProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.bluetooth_connected, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Product Nearby!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              children: [
                // Product Image Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
                const SizedBox(width: AppConstants.paddingM),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star,
                              color: Colors.orange.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating} (${product.reviewCount})',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingM,
              0,
              AppConstants.paddingM,
              AppConstants.paddingM,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productId: product.id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Product Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the active beacon and current product providers
    final activeBeaconAsync = ref.watch(activeBeaconProvider);
    final currentProductAsync = ref.watch(currentProductProvider);
    final relPosAsync = ref.watch(twoBeaconRelativePositionProvider);
    final closestShopAsync = ref.watch(closestShopCategoryProvider);
    final closestShopItemsAsync = ref.watch(closestShopProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Shopping'),
        centerTitle: true,
        actions: [
          // BLE Status Indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: activeBeaconAsync.when(
                data: (beaconId) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: beaconId != null ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    beaconId != null ? 'Beacon: $beaconId' : 'Scanning...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                loading: () => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Scanning...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                error: (_, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShoppingListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section (moved to top)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.primaryDarkColor,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Smart Shopping!',
                    style: AppConstants.headlineMedium.copyWith(
                      color: AppConstants.textOnPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    'Walk near any product to see instant details, prices, and reviews.',
                    style: AppConstants.bodyLarge.copyWith(
                      color: AppConstants.textOnPrimaryColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Nearby Product Section (between welcome and quick actions)
            currentProductAsync.when(
              data: (product) {
                if (product == null) return const SizedBox.shrink();

                return _buildNearbyProductCard(product);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppConstants.paddingL),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),

            // Closest Shop proximity + items
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingL,
                vertical: AppConstants.paddingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nearest Shop', style: AppConstants.titleLarge),
                  const SizedBox(height: AppConstants.paddingS),
                  _buildProximityIndicator(relPosAsync, closestShopAsync),
                  const SizedBox(height: AppConstants.paddingM),
                  closestShopItemsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const Text(
                            'Move closer to a shop to see items.');
                      }
                      return _buildProductsGrid(items);
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.paddingM),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: AppConstants.titleLarge),
                  const SizedBox(height: AppConstants.paddingM),

                  // Action Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppConstants.paddingM,
                    mainAxisSpacing: AppConstants.paddingM,
                    children: [
                      _buildActionCard(
                        icon: Icons.qr_code_scanner,
                        title: 'Scan Product',
                        subtitle: 'Scan nearby beacons',
                        onTap: () {
                          // Navigate to product scanning/detection
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductDetailScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        icon: Icons.compare_arrows,
                        title: 'Compare Products',
                        subtitle: 'Compare multiple items',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ComparisonScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        icon: Icons.list_alt,
                        title: 'Shopping List',
                        subtitle: 'Manage your list',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShoppingListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        icon: Icons.settings,
                        title: 'Settings',
                        subtitle: 'App preferences',
                        onTap: () {
                          _showSettingsDialog(context);
                        },
                      ),
                      // NEW: Mall Navigation Card
                      _buildActionCard(
                        icon: Icons.map,
                        title: 'Mall Navigation',
                        subtitle: 'Indoor navigation demo',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MallNavigationDemoPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // How It Works Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppConstants.paddingL),
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: AppConstants.elevationM,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How It Works', style: AppConstants.titleLarge),
                  const SizedBox(height: AppConstants.paddingM),
                  _buildHowItWorksStep(
                    step: '1',
                    title: 'Walk Near Products',
                    description:
                        'Simply walk close to any product with a beacon',
                  ),
                  _buildHowItWorksStep(
                    step: '2',
                    title: 'Automatic Detection',
                    description:
                        'The app automatically detects the closest product',
                  ),
                  _buildHowItWorksStep(
                    step: '3',
                    title: 'Instant Information',
                    description:
                        'View prices, reviews, and detailed product info',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build action card widget
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppConstants.iconSizeXL,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                title,
                style: AppConstants.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingXS),
              Text(
                subtitle,
                style: AppConstants.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProximityIndicator(
    AsyncValue<double?> relPosAsync,
    AsyncValue<String?> closestShopAsync,
  ) {
    final t = relPosAsync.value;
    final closest = closestShopAsync.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Clothing (101)'),
                Text('Electrical (102)'),
              ],
            ),
            const SizedBox(height: AppConstants.paddingS),
            SizedBox(
              height: 36,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final dx = t == null ? null : (t.clamp(0.0, 1.0) * width);
                  return Stack(
                    children: [
                      // Track
                      Positioned.fill(
                        top: 16,
                        child: Container(
                          height: 4,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      // Dot
                      if (dx != null)
                        Positioned(
                          left: (dx - 8).clamp(0.0, width - 16),
                          top: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              closest != null
                  ? 'Closest shop: $closest'
                  : 'No beacons detected yet',
              style: AppConstants.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppConstants.paddingM,
        crossAxisSpacing: AppConstants.paddingM,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(productId: p.id),
              ),
            );
          },
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: Colors.grey.shade200,
                    child:
                        const Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppConstants.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${p.price.toStringAsFixed(2)}',
                        style: AppConstants.titleMedium.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build how it works step widget
  Widget _buildHowItWorksStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: AppConstants.titleSmall.copyWith(
                  color: AppConstants.textOnPrimaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppConstants.titleMedium),
                const SizedBox(height: AppConstants.paddingXS),
                Text(description, style: AppConstants.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show settings dialog
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bluetooth Settings'),
              SwitchListTile(
                title: Text('Enable Bluetooth Scanning'),
                value: true,
                onChanged: null, // TODO: Implement
              ),
              Text('Notification Settings'),
              SwitchListTile(
                title: Text('Product Notifications'),
                value: true,
                onChanged: null, // TODO: Implement
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
