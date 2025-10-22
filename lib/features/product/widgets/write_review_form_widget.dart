import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/product_provider.dart';

/// Widget for writing a new product review
class WriteReviewFormWidget extends ConsumerWidget {
  final String productId;

  const WriteReviewFormWidget({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(reviewFormProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Write a Review', style: AppConstants.titleLarge),
          const SizedBox(height: AppConstants.paddingL),

          // Rating section
          Text('Rating', style: AppConstants.titleMedium),
          const SizedBox(height: AppConstants.paddingS),
          _buildRatingSelector(ref, formState.rating),

          const SizedBox(height: AppConstants.paddingL),

          // Comment section
          Text('Your Review', style: AppConstants.titleMedium),
          const SizedBox(height: AppConstants.paddingS),
          TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts about this product...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(reviewFormProvider.notifier).updateComment(value);
            },
          ),

          // Error message
          if (formState.error != null) ...[
            const SizedBox(height: AppConstants.paddingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                border: Border.all(
                  color: AppConstants.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppConstants.errorColor,
                    size: AppConstants.iconSizeS,
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Expanded(
                    child: Text(
                      formState.error!,
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Success message
          if (formState.isSuccess) ...[
            const SizedBox(height: AppConstants.paddingM),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                border: Border.all(
                  color: AppConstants.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppConstants.successColor,
                    size: AppConstants.iconSizeS,
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Expanded(
                    child: Text(
                      'Thank you! Your review has been submitted.',
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppConstants.paddingL),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: formState.isSubmitting
                    ? null
                    : () {
                        ref.read(reviewFormProvider.notifier).reset();
                        Navigator.of(context).pop();
                      },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppConstants.paddingM),
              ElevatedButton(
                onPressed: formState.isSubmitting
                    ? null
                    : () {
                        _submitReview(context, ref);
                      },
                child: formState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.textOnPrimaryColor,
                          ),
                        ),
                      )
                    : const Text('Submit Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build rating selector
  Widget _buildRatingSelector(WidgetRef ref, double currentRating) {
    return Row(
      children: List.generate(5, (index) {
        final starRating = index + 1.0;
        final isSelected = starRating <= currentRating;

        return GestureDetector(
          onTap: () {
            ref.read(reviewFormProvider.notifier).updateRating(starRating);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingXS),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected
                  ? AppConstants.ratingColor
                  : AppConstants.ratingDisabledColor,
              size: AppConstants.iconSizeL,
            ),
          ),
        );
      }),
    );
  }

  /// Submit the review
  void _submitReview(BuildContext context, WidgetRef ref) async {
    // TODO: Get user info from authentication service
    const userId = 'user123'; // Placeholder
    const userName = 'Test User'; // Placeholder

    await ref
        .read(reviewFormProvider.notifier)
        .submitReview(productId, userId, userName, ref);

    final formState = ref.read(reviewFormProvider);
    if (formState.isSuccess) {
      // Close dialog after successful submission
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }
}
