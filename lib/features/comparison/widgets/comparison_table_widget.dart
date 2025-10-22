import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/product_model.dart';

/// Widget to display products comparison in a table format
class ComparisonTableWidget extends StatelessWidget {
  final List<Product> products;

  const ComparisonTableWidget({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Table(
          border: TableBorder.all(
            color: AppConstants.textDisabledColor,
            width: 1,
          ),
          columnWidths: _getColumnWidths(),
          children: [
            _buildHeaderRow(),
            _buildImageRow(),
            _buildNameRow(),
            _buildBrandRow(),
            _buildPriceRow(),
            _buildDiscountRow(),
            _buildRatingRow(),
            _buildCategoryRow(),
            _buildAvailabilityRow(),
            _buildDescriptionRow(),
            _buildFeaturesRow(),
            _buildActionRow(context),
          ],
        ),
      ),
    );
  }

  /// Get column widths for the table
  Map<int, TableColumnWidth> _getColumnWidths() {
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(120), // Labels column
    };

    // Product columns
    for (int i = 0; i < products.length; i++) {
      columnWidths[i + 1] = const FixedColumnWidth(200);
    }

    return columnWidths;
  }

  /// Build header row with product images thumbnails
  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: AppConstants.primaryLightColor),
      children: [
        _buildLabelCell('Products'),
        ...products.map((product) => _buildProductHeaderCell(product)),
      ],
    );
  }

  /// Build product image row
  TableRow _buildImageRow() {
    return TableRow(
      children: [
        _buildLabelCell('Image'),
        ...products.map((product) => _buildImageCell(product)),
      ],
    );
  }

  /// Build product name row
  TableRow _buildNameRow() {
    return TableRow(
      children: [
        _buildLabelCell('Name'),
        ...products.map((product) => _buildTextCell(product.name)),
      ],
    );
  }

  /// Build brand row
  TableRow _buildBrandRow() {
    return TableRow(
      children: [
        _buildLabelCell('Brand'),
        ...products.map(
          (product) =>
              _buildTextCell(product.brand.isNotEmpty ? product.brand : 'N/A'),
        ),
      ],
    );
  }

  /// Build price row
  TableRow _buildPriceRow() {
    return TableRow(
      children: [
        _buildLabelCell('Price'),
        ...products.map((product) => _buildPriceCell(product)),
      ],
    );
  }

  /// Build discount row
  TableRow _buildDiscountRow() {
    return TableRow(
      children: [
        _buildLabelCell('Discount'),
        ...products.map((product) => _buildDiscountCell(product)),
      ],
    );
  }

  /// Build rating row
  TableRow _buildRatingRow() {
    return TableRow(
      children: [
        _buildLabelCell('Rating'),
        ...products.map((product) => _buildRatingCell(product)),
      ],
    );
  }

  /// Build category row
  TableRow _buildCategoryRow() {
    return TableRow(
      children: [
        _buildLabelCell('Category'),
        ...products.map(
          (product) => _buildTextCell(
            product.category.isNotEmpty ? product.category : 'N/A',
          ),
        ),
      ],
    );
  }

  /// Build availability row
  TableRow _buildAvailabilityRow() {
    return TableRow(
      children: [
        _buildLabelCell('Availability'),
        ...products.map((product) => _buildAvailabilityCell(product)),
      ],
    );
  }

  /// Build description row
  TableRow _buildDescriptionRow() {
    return TableRow(
      children: [
        _buildLabelCell('Description'),
        ...products.map(
          (product) => _buildTextCell(product.description, maxLines: 3),
        ),
      ],
    );
  }

  /// Build features row
  TableRow _buildFeaturesRow() {
    return TableRow(
      children: [
        _buildLabelCell('Features'),
        ...products.map((product) => _buildFeaturesCell(product)),
      ],
    );
  }

  /// Build action row with buttons
  TableRow _buildActionRow(BuildContext context) {
    return TableRow(
      children: [
        _buildLabelCell('Actions'),
        ...products.map((product) => _buildActionCell(context, product)),
      ],
    );
  }

  /// Build label cell for row headers
  Widget _buildLabelCell(String label) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: const BoxDecoration(color: AppConstants.backgroundColor),
      child: Text(
        label,
        style: AppConstants.titleSmall.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Build product header cell
  Widget _buildProductHeaderCell(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
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
                    size: AppConstants.iconSizeL,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            product.name,
            style: AppConstants.titleSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build image cell
  Widget _buildImageCell(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        child: Image.network(
          product.imageUrl,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 120,
              height: 120,
              color: AppConstants.backgroundColor,
              child: const Icon(
                Icons.image_not_supported,
                color: AppConstants.textDisabledColor,
                size: AppConstants.iconSizeXL,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build text cell
  Widget _buildTextCell(String text, {int maxLines = 2}) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Text(
        text,
        style: AppConstants.bodyMedium,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Build price cell
  Widget _buildPriceCell(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.hasDiscount) ...[
            Text(
              AppConstants.formatPrice(product.discountedPrice),
              style: AppConstants.priceStyleMedium,
            ),
            const SizedBox(height: AppConstants.paddingXS),
            Text(
              AppConstants.formatPrice(product.price),
              style: AppConstants.originalPriceStyle,
            ),
          ] else
            Text(
              AppConstants.formatPrice(product.price),
              style: AppConstants.priceStyleMedium,
            ),
        ],
      ),
    );
  }

  /// Build discount cell
  Widget _buildDiscountCell(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: product.hasDiscount
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingS,
                vertical: AppConstants.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppConstants.discountColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              ),
              child: Text(
                AppConstants.formatDiscount(product.discount),
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textOnPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Text(
              'No discount',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),
    );
  }

  /// Build rating cell
  Widget _buildRatingCell(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: AppConstants.getRatingStars(
              product.rating,
              size: AppConstants.iconSizeS,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            '${AppConstants.formatRating(product.rating)} (${product.reviewCount})',
            style: AppConstants.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Build availability cell
  Widget _buildAvailabilityCell(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingS,
          vertical: AppConstants.paddingXS,
        ),
        decoration: BoxDecoration(
          color: product.isAvailable
              ? AppConstants.successColor
              : AppConstants.errorColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        ),
        child: Text(
          product.isAvailable ? 'In Stock' : 'Out of Stock',
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textOnPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Build features cell
  Widget _buildFeaturesCell(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: product.features.isEmpty
          ? Text(
              'No features listed',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: product.features
                  .take(3)
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.paddingXS,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check,
                            size: AppConstants.iconSizeS,
                            color: AppConstants.successColor,
                          ),
                          const SizedBox(width: AppConstants.paddingXS),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppConstants.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// Build action cell with buttons
  Widget _buildActionCell(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: product.isAvailable
                  ? () {
                      // Navigate to product detail
                      Navigator.pushNamed(
                        context,
                        '/product',
                        arguments: product.id,
                      );
                    }
                  : null,
              child: const Text('View Details'),
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: product.isAvailable
                  ? () {
                      // Add to cart
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          backgroundColor: AppConstants.successColor,
                        ),
                      );
                    }
                  : null,
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}
