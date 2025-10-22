import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared_widgets/loading_spinner.dart';
import '../providers/product_provider.dart';
import '../widgets/review_card_widget.dart';
import '../widgets/write_review_form_widget.dart';
import 'all_reviews_screen.dart';

/// Product detail screen showing comprehensive product information
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductDetailScreen({super.key, this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _lastKnownProduct;

  @override
  void initState() {
    super.initState();
    // Start BLE scanning when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bleScanningStateProvider.notifier).startScanning();
    });
  }

  @override
  void dispose() {
    // Stop BLE scanning when leaving screen
    ref.read(bleScanningStateProvider.notifier).stopScanning();
    super.dispose();
  }

  /// Send notification when product changes while user is viewing details
  Future<void> _sendProductChangeNotification(Product product) async {
    try {
      await NotificationService().showProductChangeNotification(
        productName: product.name,
        productId: product.id,
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which product to show
    final productAsyncValue = widget.productId != null
        ? ref.watch(productByIdProvider(widget.productId!))
        : ref.watch(currentProductProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: productAsyncValue.when(
        data: (product) {
          if (product == null) {
            return _buildNoProductView();
          }

          // Check if product changed and send notification
          if (_lastKnownProduct != null &&
              _lastKnownProduct!.id != product.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _sendProductChangeNotification(product);
            });
          }
          _lastKnownProduct = product;

          return _buildProductView(product);
        },
        loading: () => const LoadingSpinner(),
        error: (error, stack) => _buildErrorView(error.toString()),
      ),
    );
  }

  /// Build view when no product is detected
  Widget _buildNoProductView() {
    final scanningState = ref.watch(bleScanningStateProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: AppConstants.iconSizeXL * 2,
              color: AppConstants.textSecondaryColor,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              scanningState == BleScanningState.scanning
                  ? 'Scanning for products...'
                  : 'No product detected',
              style: AppConstants.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Walk near a product with a beacon to see details',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingL),
            if (scanningState != BleScanningState.scanning)
              ElevatedButton(
                onPressed: () {
                  ref.read(bleScanningStateProvider.notifier).startScanning();
                },
                child: const Text('Start Scanning'),
              ),

            // Demo buttons for testing
            const SizedBox(height: AppConstants.paddingL),
            const Divider(),
            const Text('Demo Mode', style: AppConstants.titleMedium),
            const SizedBox(height: AppConstants.paddingM),
            Wrap(
              spacing: AppConstants.paddingS,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(bleScanningStateProvider.notifier)
                        .simulateBeacon('101');
                  },
                  child: const Text('Product 101'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(bleScanningStateProvider.notifier)
                        .simulateBeacon('102');
                  },
                  child: const Text('Product 102'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(bleScanningStateProvider.notifier)
                        .simulateBeacon('103');
                  },
                  child: const Text('Product 103'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build main product view
  Widget _buildProductView(Product product) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          _buildProductImage(product),

          // Product Info
          _buildProductInfo(product),

          // Action Buttons
          _buildActionButtons(product),

          // Reviews Section
          _buildReviewsSection(product),
        ],
      ),
    );
  }

  /// Build product image section
  Widget _buildProductImage(Product product) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        image: DecorationImage(
          image: NetworkImage(product.imageUrl),
          fit: BoxFit.contain,
          onError: (exception, stackTrace) {
            // Handle image load error
          },
        ),
      ),
      child: Stack(
        children: [
          // Discount badge
          if (product.hasDiscount)
            Positioned(
              top: AppConstants.paddingM,
              right: AppConstants.paddingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingS,
                  vertical: AppConstants.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.discountColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusS,
                  ),
                ),
                child: Text(
                  AppConstants.formatDiscount(product.discount),
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textOnPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build product information section
  Widget _buildProductInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(product.name, style: AppConstants.headlineSmall),
          const SizedBox(height: AppConstants.paddingS),

          // Brand and category
          if (product.brand.isNotEmpty || product.category.isNotEmpty)
            Row(
              children: [
                if (product.brand.isNotEmpty) ...[
                  Text(
                    product.brand,
                    style: AppConstants.bodyMedium.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                  if (product.category.isNotEmpty)
                    Text(
                      ' • ${product.category}',
                      style: AppConstants.bodyMedium.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                ] else
                  Text(
                    product.category,
                    style: AppConstants.bodyMedium.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: AppConstants.paddingM),

          // Price section
          Row(
            children: [
              if (product.hasDiscount) ...[
                Text(
                  AppConstants.formatPrice(product.discountedPrice),
                  style: AppConstants.priceStyleLarge,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  AppConstants.formatPrice(product.price),
                  style: AppConstants.originalPriceStyle,
                ),
              ] else
                Text(
                  AppConstants.formatPrice(product.price),
                  style: AppConstants.priceStyleLarge,
                ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Rating and reviews
          Row(
            children: [
              ...AppConstants.getRatingStars(product.rating),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                AppConstants.formatRating(product.rating),
                style: AppConstants.bodyMedium,
              ),
              Text(
                ' (${product.reviewCount} reviews)',
                style: AppConstants.bodyMedium.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingL),

          // Description
          Text('Description', style: AppConstants.titleMedium),
          const SizedBox(height: AppConstants.paddingS),
          Text(product.description, style: AppConstants.bodyMedium),

          // Features
          if (product.features.isNotEmpty) ...[
            const SizedBox(height: AppConstants.paddingL),
            Text('Features', style: AppConstants.titleMedium),
            const SizedBox(height: AppConstants.paddingS),
            ...product.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingXS,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: AppConstants.iconSizeS,
                      color: AppConstants.successColor,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(feature, style: AppConstants.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build action buttons section
  Widget _buildActionButtons(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: product.isAvailable
                  ? () {
                      // TODO: Add to cart functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: AppConstants.successColor,
                        ),
                      );
                    }
                  : null,
              child: Text(product.isAvailable ? 'Add to Cart' : 'Out of Stock'),
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          OutlinedButton(
            onPressed: () {
              // TODO: Add to wishlist functionality
            },
            child: const Icon(Icons.favorite_border),
          ),
          const SizedBox(width: AppConstants.paddingS),
          OutlinedButton(
            onPressed: () {
              context.navigateToComparison([product.id]);
            },
            child: const Icon(Icons.compare_arrows),
          ),
        ],
      ),
    );
  }

  /// Build reviews section
  Widget _buildReviewsSection(Product product) {
    final reviewsAsyncValue = ref.watch(productReviewsProvider(product.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.paddingL),
        const Divider(),

        // Reviews header
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews (${product.reviewCount})',
                style: AppConstants.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllReviewsScreen(productId: product.id),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),

        // Write review button
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
          ),
          child: OutlinedButton.icon(
            onPressed: () {
              _showWriteReviewDialog(product.id);
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Write a Review'),
          ),
        ),

        const SizedBox(height: AppConstants.paddingM),

        // Reviews list
        reviewsAsyncValue.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Text(
                  'No reviews yet. Be the first to review!',
                  style: AppConstants.bodyMedium.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              );
            }

            // Show first 3 reviews
            final displayReviews = reviews.take(3).toList();
            return Column(
              children: displayReviews
                  .map((review) => ReviewCardWidget(review: review))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppConstants.paddingL),
            child: LoadingSpinner(),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Text(
              'Error loading reviews: $error',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.errorColor,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppConstants.paddingL),
      ],
    );
  }

  /// Build error view
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppConstants.iconSizeXL,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text('Error loading product', style: AppConstants.titleLarge),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              error,
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton(
              onPressed: () {
                // Retry loading
                ref.invalidate(currentProductProvider);
                if (widget.productId != null) {
                  ref.invalidate(productByIdProvider(widget.productId!));
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show write review dialog
  void _showWriteReviewDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: WriteReviewFormWidget(productId: productId),
          ),
        );
      },
    );
  }
}

/// Extension to add navigation helpers
extension NavigationExtension on BuildContext {
  void navigateToComparison(List<String> productIds) {
    // TODO: Implement comparison navigation
  }
}
