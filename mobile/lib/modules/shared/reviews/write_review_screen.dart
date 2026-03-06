import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/review_controller.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_text_field.dart';

class WriteReviewScreen extends StatefulWidget {
  final String bookingId;

  const WriteReviewScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ReviewController _reviewController = Get.find<ReviewController>();
  final TextEditingController _commentController = TextEditingController();

  int _overallRating = 0;
  int _qualityRating = 0;
  int _communicationRating = 0;
  int _punctualityRating = 0;
  int _valueRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an overall rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await _reviewController.submitReview(
      bookingId: widget.bookingId,
      revieweeId: '', // Will be resolved by the backend from the booking
      overallRating: _overallRating,
      qualityRating: _qualityRating > 0 ? _qualityRating : null,
      communicationRating:
          _communicationRating > 0 ? _communicationRating : null,
      punctualityRating:
          _punctualityRating > 0 ? _punctualityRating : null,
      valueRating: _valueRating > 0 ? _valueRating : null,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
    );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallRating(),
            const SizedBox(height: AppDimensions.lg),
            _buildCategoryRatings(),
            const SizedBox(height: AppDimensions.lg),
            _buildCommentSection(),
            const SizedBox(height: AppDimensions.xl),
            _buildSubmitButton(),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating() {
    return AppCard(
      child: Column(
        children: [
          Text(
            'Overall Rating',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'How would you rate this experience?',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _overallRating = starValue;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starValue <= _overallRating
                        ? Icons.star
                        : Icons.star_border,
                    size: 44,
                    color: AppColors.ratingStar,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            _getRatingLabel(_overallRating),
            style: AppTextStyles.bodyMedium.copyWith(
              color: _overallRating > 0
                  ? AppColors.textPrimary
                  : AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRatings() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Ratings',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Optional - rate specific aspects',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppDimensions.md),
          _CategoryRatingRow(
            label: 'Quality',
            icon: Icons.workspace_premium_outlined,
            rating: _qualityRating,
            onChanged: (value) {
              setState(() {
                _qualityRating = value;
              });
            },
          ),
          const Divider(height: AppDimensions.lg),
          _CategoryRatingRow(
            label: 'Communication',
            icon: Icons.chat_outlined,
            rating: _communicationRating,
            onChanged: (value) {
              setState(() {
                _communicationRating = value;
              });
            },
          ),
          const Divider(height: AppDimensions.lg),
          _CategoryRatingRow(
            label: 'Punctuality',
            icon: Icons.schedule_outlined,
            rating: _punctualityRating,
            onChanged: (value) {
              setState(() {
                _punctualityRating = value;
              });
            },
          ),
          const Divider(height: AppDimensions.lg),
          _CategoryRatingRow(
            label: 'Value',
            icon: Icons.payments_outlined,
            rating: _valueRating,
            onChanged: (value) {
              setState(() {
                _valueRating = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Review',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Share your experience to help others',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppDimensions.md),
        AppTextField(
          controller: _commentController,
          hint: 'Tell others about your experience with this worker...',
          maxLines: 5,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => AppButton(
          label: 'Submit Review',
          onPressed: _submitReview,
          isLoading: _reviewController.isSubmitting.value,
          icon: Icons.send,
        ));
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }
}

class _CategoryRatingRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int rating;
  final ValueChanged<int> onChanged;

  const _CategoryRatingRow({
    required this.label,
    required this.icon,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => onChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  starValue <= rating
                      ? Icons.star
                      : Icons.star_border,
                  size: 24,
                  color: AppColors.ratingStar,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
