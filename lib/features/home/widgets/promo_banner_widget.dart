import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Promotional banner widget to display offers and deals
class PromoBannerWidget extends StatelessWidget {
  const PromoBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingL),
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppConstants.secondaryColor,
            AppConstants.secondaryDarkColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: AppConstants.elevationM,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Special Offers!',
                        style: AppConstants.titleLarge.copyWith(
                          color: AppConstants.textOnPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingXS),
                      Text(
                        'Get up to 50% off on selected items',
                        style: AppConstants.bodySmall.copyWith(
                          color: AppConstants.textOnPrimaryColor.withValues(
                            alpha: 0.9,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusS,
                          ),
                        ),
                        child: Text(
                          'SHOP NOW',
                          style: AppConstants.bodySmall.copyWith(
                            color: AppConstants.textOnPrimaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Promo Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: AppConstants.textOnPrimaryColor,
                    size: AppConstants.iconSizeL,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
