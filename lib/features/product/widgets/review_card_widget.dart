import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/review_model.dart';

/// Widget to display a single review card
class ReviewCardWidget extends StatelessWidget {
  final Review review;

  const ReviewCardWidget({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppConstants.primaryLightColor,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'U',
                    style: AppConstants.titleSmall.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),

                // User name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName, style: AppConstants.titleSmall),
                      const SizedBox(height: AppConstants.paddingXS),
                      Row(
                        children: [
                          Text(
                            review.formattedDate,
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: AppConstants.paddingS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingXS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.successColor,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusS,
                                ),
                              ),
                              child: Text(
                                'Verified',
                                style: AppConstants.bodySmall.copyWith(
                                  color: AppConstants.textOnPrimaryColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Rating stars
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: AppConstants.getRatingStars(
                        review.rating,
                        size: AppConstants.iconSizeS,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      AppConstants.formatRating(review.rating),
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingM),

            // Review comment
            Text(review.comment, style: AppConstants.bodyMedium),

            // Review images
            if (review.hasImages) ...[
              const SizedBox(height: AppConstants.paddingM),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppConstants.paddingS),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusM,
                      ),
                      child: Image.network(
                        review.images[index],
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
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: AppConstants.paddingM),

            // Footer with helpful votes
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement helpful vote functionality
                  },
                  icon: const Icon(
                    Icons.thumb_up_outlined,
                    size: AppConstants.iconSizeS,
                  ),
                  label: Text(
                    'Helpful (${review.helpfulVotes})',
                    style: AppConstants.bodySmall,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.textSecondaryColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),

                // Report button
                TextButton(
                  onPressed: () {
                    _showReportDialog(context);
                  },
                  child: Text(
                    'Report',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.textSecondaryColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show report dialog
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Review'),
          content: const Text(
            'Are you sure you want to report this review as inappropriate?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement report functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Review reported. Thank you for your feedback.',
                    ),
                  ),
                );
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }
}
