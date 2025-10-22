import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/product_model.dart';
import '../../../shared_widgets/loading_spinner.dart';
import '../../product/providers/product_provider.dart';
import '../widgets/comparison_table_widget.dart';

/// Screen for comparing multiple products side by side
class ComparisonScreen extends ConsumerStatefulWidget {
  final List<String>? initialProductIds;

  const ComparisonScreen({super.key, this.initialProductIds});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  List<String> selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialProductIds != null) {
      selectedProductIds = List.from(widget.initialProductIds!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showProductSelectionDialog,
          ),
        ],
      ),
      body: selectedProductIds.isEmpty
          ? _buildEmptyState()
          : _buildComparisonView(),
    );
  }

  /// Build empty state when no products are selected
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: AppConstants.iconSizeXL * 2,
              color: AppConstants.textDisabledColor,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              'No Products to Compare',
              style: AppConstants.titleLarge.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Add products to compare their features, prices, and ratings side by side.',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingL),
            ElevatedButton.icon(
              onPressed: _showProductSelectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Products'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build comparison view with selected products
  Widget _buildComparisonView() {
    final productsAsyncValue = ref.watch(
      comparisonProductsProvider(selectedProductIds),
    );

    return productsAsyncValue.when(
      data: (products) {
        if (products.isEmpty) {
          return _buildErrorState('No products found');
        }
        return _buildComparisonContent(products);
      },
      loading: () => const LoadingSpinner(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  /// Build main comparison content
  Widget _buildComparisonContent(List<Product> products) {
    return Column(
      children: [
        // Header with product count and actions
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: const BoxDecoration(
            color: AppConstants.surfaceColor,
            border: Border(
              bottom: BorderSide(
                color: AppConstants.textDisabledColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Comparing ${products.length} ${products.length == 1 ? 'Product' : 'Products'}',
                style: AppConstants.titleMedium,
              ),
              const Spacer(),
              if (products.length < AppConstants.maxProductsInComparison)
                TextButton.icon(
                  onPressed: _showProductSelectionDialog,
                  icon: const Icon(Icons.add, size: AppConstants.iconSizeS),
                  label: const Text('Add'),
                ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedProductIds.clear();
                  });
                },
                icon: const Icon(Icons.clear_all, size: AppConstants.iconSizeS),
                label: const Text('Clear All'),
              ),
            ],
          ),
        ),

        // Comparison table
        Expanded(
          child: SingleChildScrollView(
            child: ComparisonTableWidget(products: products),
          ),
        ),
      ],
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
            Text('Error Loading Products', style: AppConstants.titleLarge),
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
                ref.invalidate(comparisonProductsProvider(selectedProductIds));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to select products for comparison
  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: _ProductSelectionDialog(
              selectedProductIds: selectedProductIds,
              onProductsSelected: (newProductIds) {
                setState(() {
                  selectedProductIds = newProductIds;
                });
              },
            ),
          ),
        );
      },
    );
  }
}

/// Dialog for selecting products to compare
class _ProductSelectionDialog extends ConsumerStatefulWidget {
  final List<String> selectedProductIds;
  final Function(List<String>) onProductsSelected;

  const _ProductSelectionDialog({
    required this.selectedProductIds,
    required this.onProductsSelected,
  });

  @override
  ConsumerState<_ProductSelectionDialog> createState() =>
      _ProductSelectionDialogState();
}

class _ProductSelectionDialogState
    extends ConsumerState<_ProductSelectionDialog> {
  List<String> tempSelectedIds = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    tempSelectedIds = List.from(widget.selectedProductIds);
  }

  @override
  Widget build(BuildContext context) {
    final allProductsAsyncValue = ref.watch(allProductsProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppConstants.textDisabledColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Products to Compare',
                style: AppConstants.titleLarge,
              ),
              const SizedBox(height: AppConstants.paddingM),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ],
          ),
        ),

        // Product list
        Expanded(
          child: allProductsAsyncValue.when(
            data: (products) {
              final filteredProducts = searchQuery.isEmpty
                  ? products
                  : products
                        .where(
                          (product) =>
                              product.name.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ) ||
                              product.category.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ) ||
                              product.brand.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

              if (filteredProducts.isEmpty) {
                return const Center(
                  child: Text(
                    'No products found',
                    style: AppConstants.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final isSelected = tempSelectedIds.contains(product.id);
                  final canSelect =
                      tempSelectedIds.length <
                      AppConstants.maxProductsInComparison;

                  return Card(
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: canSelect || isSelected
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  tempSelectedIds.add(product.id);
                                } else {
                                  tempSelectedIds.remove(product.id);
                                }
                              });
                            }
                          : null,
                      title: Text(
                        product.name,
                        style: AppConstants.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.brand.isNotEmpty)
                            Text(
                              product.brand,
                              style: AppConstants.bodySmall.copyWith(
                                color: AppConstants.textSecondaryColor,
                              ),
                            ),
                          Text(
                            AppConstants.formatPrice(product.price),
                            style: AppConstants.priceStyleMedium.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusS,
                        ),
                        child: Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: AppConstants.backgroundColor,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: AppConstants.textDisabledColor,
                                size: AppConstants.iconSizeS,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const LoadingSpinner(),
            error: (error, stack) => Center(
              child: Text(
                'Error loading products: $error',
                style: AppConstants.bodyMedium.copyWith(
                  color: AppConstants.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Footer with actions
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppConstants.textDisabledColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${tempSelectedIds.length}/${AppConstants.maxProductsInComparison} selected',
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppConstants.paddingM),
              ElevatedButton(
                onPressed: tempSelectedIds.isNotEmpty
                    ? () {
                        widget.onProductsSelected(tempSelectedIds);
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Compare'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
