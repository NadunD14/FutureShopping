import 'package:flutter/material.dart';

/// Application constants including colors, text styles, and other shared values
class AppConstants {
  AppConstants._();

  // ==================== Colors ====================
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFFBBDEFB);

  static const Color secondaryColor = Color(0xFFFF9800); // Orange
  static const Color secondaryDarkColor = Color(0xFFF57C00);
  static const Color secondaryLightColor = Color(0xFFFFE0B2);

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFF9800);

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textDisabledColor = Color(0xFFBDBDBD);
  static const Color textOnPrimaryColor = Colors.white;

  // Price Colors
  static const Color priceColor = Color(0xFF1B5E20); // Dark Green
  static const Color discountColor = Color(0xFFD32F2F); // Red
  static const Color originalPriceColor = Color(0xFF757575); // Gray

  // Rating Colors
  static const Color ratingColor = Color(0xFFFF9800); // Orange
  static const Color ratingDisabledColor = Color(0xFFE0E0E0);

  // ==================== Text Styles ====================

  // Headlines
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.25,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    height: 1.3,
  );

  // Titles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    height: 1.4,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
    height: 1.4,
  );

  // Price Styles
  static const TextStyle priceStyleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: priceColor,
    height: 1.2,
  );

  static const TextStyle priceStyleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: priceColor,
    height: 1.3,
  );

  static const TextStyle discountPriceStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: discountColor,
    height: 1.3,
  );

  static const TextStyle originalPriceStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: originalPriceColor,
    decoration: TextDecoration.lineThrough,
    height: 1.3,
  );

  // Button Styles
  static const TextStyle buttonTextLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textOnPrimaryColor,
    height: 1.2,
  );

  static const TextStyle buttonTextMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textOnPrimaryColor,
    height: 1.2,
  );

  // ==================== Dimensions ====================

  // Padding and Margins
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;

  // Icon Sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // ==================== Animation Durations ====================
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  // ==================== App Specific Constants ====================

  // BLE Configuration
  static const String defaultBeaconServiceUuid =
      '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const int defaultRssiThreshold = -80;
  static const int defaultHysteresisBuffer = 5;
  static const Duration defaultScanTimeout = Duration(seconds: 5);

  // Product Configuration
  static const int maxProductsInComparison = 3;
  static const int maxReviewsPerPage = 10;
  static const double minRating = 1.0;
  static const double maxRating = 5.0;

  // Image Configuration
  static const String placeholderImageUrl =
      'https://via.placeholder.com/300x300?text=No+Image';
  static const double productImageAspectRatio = 1.0; // Square images

  // Currency
  static const String currencySymbol = 'LKR';
  static const String currencyCode = 'LKR';

  // ==================== Helper Methods ====================

  /// Format price with currency symbol
  static String formatPrice(double price) {
    return '$currencySymbol ${price.toStringAsFixed(2)}';
  }

  /// Format discount percentage
  static String formatDiscount(double discount) {
    return '${discount.toStringAsFixed(0)}% OFF';
  }

  /// Format rating display
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Get star icons for rating
  static List<Widget> getRatingStars(double rating, {double size = iconSizeM}) {
    final stars = <Widget>[];
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;

    // Full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: ratingColor, size: size));
    }

    // Half star
    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: ratingColor, size: size));
    }

    // Empty stars
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    for (int i = 0; i < emptyStars; i++) {
      stars.add(
        Icon(Icons.star_border, color: ratingDisabledColor, size: size),
      );
    }

    return stars;
  }
}
