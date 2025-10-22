import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared_widgets/loading_spinner.dart';
import '../providers/product_provider.dart';
import '../widgets/review_card_widget.dart';

/// Screen showing all reviews for a product
class AllReviewsScreen extends ConsumerWidget {
  final String productId;

  const AllReviewsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsyncValue = ref.watch(productReviewsProvider(productId));
    final productAsyncValue = ref.watch(productByIdProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('All Reviews')),
      body: Column(
        children: [
          // Product summary header
          productAsyncValue.when(
            data: (product) {
              if (product == null) return const SizedBox.shrink();
              return _buildProductSummary(product);
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Reviews list
          Expanded(
            child: reviewsAsyncValue.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildReviewsList(reviews);
              },
              loading: () => const LoadingSpinner(),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  /// Build product summary at the top
  Widget _buildProductSummary(product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppConstants.textDisabledColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            child: Image.network(
              product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: AppConstants.backgroundColor,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: AppConstants.textDisabledColor,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppConstants.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Row(
                  children: [
                    ...AppConstants.getRatingStars(product.rating),
                    const SizedBox(width: AppConstants.paddingS),
                    Text(
                      '${AppConstants.formatRating(product.rating)} (${product.reviewCount})',
                      style: AppConstants.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingXS),
                Text(
                  AppConstants.formatPrice(product.price),
                  style: AppConstants.priceStyleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build reviews list
  Widget _buildReviewsList(reviews) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: reviews.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.paddingM),
      itemBuilder: (context, index) {
        return ReviewCardWidget(review: reviews[index]);
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: AppConstants.iconSizeXL * 2,
              color: AppConstants.textDisabledColor,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              'No Reviews Yet',
              style: AppConstants.titleLarge.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Be the first to share your thoughts about this product!',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
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
            Text('Error Loading Reviews', style: AppConstants.titleLarge),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              error,
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
