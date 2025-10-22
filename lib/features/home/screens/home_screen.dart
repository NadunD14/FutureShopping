import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/ble_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/firebase_data_seeder.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/product_model.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../comparison/screens/comparison_screen.dart';
import '../../shopping_list/screens/shopping_list_screen.dart';

/// Home screen - main welcome screen of the app
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Product? nearbyProduct;
  List<Product> nearbyProducts = [];
  bool isScanning = false;
  String? activeBeaconId;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize notification service
    await NotificationService().initialize();

    // Ensure Firebase has sample data for testing
    await FirebaseDataSeeder.seedSampleData();

    // Start BLE scanning
    _startBeaconScanning();
  }

  Future<void> _startBeaconScanning() async {
    setState(() {
      isScanning = true;
    });

    // Listen to beacon changes
    BleService.instance.activeBeaconStream.listen((beaconId) async {
      if (mounted) {
        setState(() {
          activeBeaconId = beaconId;
          isScanning =
              beaconId == null; // Stop showing scanning when beacon found
        });

        if (beaconId != null) {
          print('Beacon detected: $beaconId - Fetching products...');
          // Fetch products based on beacon category
          final products = await _getProductsForBeacon(beaconId);
          if (mounted) {
            // Check if this is a new product change
            final newProduct = products.isNotEmpty ? products.first : null;
            final isNewProduct = nearbyProduct?.id != newProduct?.id;

            setState(() {
              nearbyProducts = products;
              nearbyProduct = newProduct;
            });

            // Send notification for product change
            if (isNewProduct && newProduct != null) {
              _sendProductChangeNotification(newProduct);
            }
          }
        } else {
          if (mounted) {
            setState(() {
              nearbyProduct = null;
              nearbyProducts = [];
            });
          }
        }
      }
    });

    // Start scanning
    await BleService.instance.startScanning();
  }

  @override
  void dispose() {
    BleService.instance.stopScanning();
    super.dispose();
  }

  Future<List<Product>> _getProductsForBeacon(String beaconId) async {
    try {
      List<Product> products = [];

      // First try to get specific product by ID
      final singleProduct =
          await FirestoreService.instance.getProduct(beaconId);
      if (singleProduct != null) {
        products = [singleProduct];
        print(
            'Found specific product for beacon $beaconId: ${singleProduct.name}');
        return products;
      }

      // If no specific product found, get products by category based on beacon ID
      String category;
      switch (beaconId) {
        case '101':
          category = 'Electronics';
          break;
        case '102':
          category = 'Electronics'; // Fallback to Electronics for now
          break;
        case '103':
          category = 'Electronics'; // Fallback to Electronics for now
          break;
        default:
          category = 'Electronics'; // Default category
      }

      products =
          await FirestoreService.instance.getProductsByCategory(category);

      // If no products found by category, get all products as fallback
      if (products.isEmpty) {
        print(
            'No products found for category $category, fetching all products');
        products = await FirestoreService.instance.getAllProducts();
      }

      print('Found ${products.length} products for beacon $beaconId');
      return products;
    } catch (e) {
      print('Error fetching products for beacon $beaconId: $e');
      // Fallback: try to get all products
      try {
        final allProducts = await FirestoreService.instance.getAllProducts();
        print('Fallback: Found ${allProducts.length} products');
        return allProducts;
      } catch (fallbackError) {
        print('Fallback failed: $fallbackError');
        return [];
      }
    }
  }

  /// Send notification when product changes
  Future<void> _sendProductChangeNotification(Product product) async {
    try {
      await NotificationService().showProductChangeNotification(
        productName: product.name,
        productId: product.id,
        price: AppConstants.formatPrice(product.price),
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Widget _buildNearbyProductCard() {
    if (nearbyProduct == null) return const SizedBox.shrink();

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
                        nearbyProduct!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${nearbyProduct!.price.toStringAsFixed(2)}',
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
                            '${nearbyProduct!.rating} (${nearbyProduct!.reviewCount})',
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
                        productId: nearbyProduct!.id,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Shopping'),
        centerTitle: true,
        actions: [
          // BLE Status Indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activeBeaconId != null ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activeBeaconId != null
                      ? 'Beacon: $activeBeaconId'
                      : 'Scanning...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

            // Nearby Product Section (moved to bottom)
            if (nearbyProduct != null) _buildNearbyProductCard(),
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
