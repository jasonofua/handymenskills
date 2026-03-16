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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Write a Review', style: AppTextStyles.h4),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Worker/service avatar placeholder
            _buildServiceHeader(),
            const SizedBox(height: AppDimensions.xl),

            // Overall rating section
            _buildOverallRating(),
            const SizedBox(height: AppDimensions.lg),

            // Category ratings
            _buildCategoryRatings(),
            const SizedBox(height: AppDimensions.lg),

            // Feedback textarea
            _buildFeedbackSection(),
            const SizedBox(height: AppDimensions.xl),

            // Submit button
            _buildSubmitButton(),

            // Skip button
            const SizedBox(height: AppDimensions.md),
            _buildSkipButton(),

            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeader() {
    return Column(
      children: [
        // Large centered avatar placeholder
        Container(
          width: AppDimensions.avatarXl,
          height: AppDimensions.avatarXl,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.person,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Text(
          'Rate Your Experience',
          style: AppTextStyles.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Your feedback helps improve service quality',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOverallRating() {
    return AppCard(
      child: Column(
        children: [
          Text(
            'How would you rate the service?',
            style: AppTextStyles.labelLarge.copyWith(
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.lg),

          // Large star rating buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = starValue <= _overallRating;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _overallRating = starValue;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: isSelected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppDimensions.sm),

          // Rating label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(_overallRating),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _overallRating > 0
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                _getRatingLabel(_overallRating),
                style: AppTextStyles.labelMedium.copyWith(
                  color: _overallRating > 0
                      ? AppColors.primary
                      : AppColors.textHint,
                  fontWeight: _overallRating > 0
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
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
            'DETAILED RATINGS',
            style: AppTextStyles.sectionHeader,
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
          Divider(
            height: AppDimensions.lg,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
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
          Divider(
            height: AppDimensions.lg,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
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
          Divider(
            height: AppDimensions.lg,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
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

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR FEEDBACK',
          style: AppTextStyles.sectionHeader,
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
          trailingIcon: Icons.arrow_forward,
          onPressed: _submitReview,
          isLoading: _reviewController.isSubmitting.value,
        ));
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: () => context.pop(),
      child: Text(
        'Skip for now',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppDimensions.sm + 2),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= rating;
            return GestureDetector(
              onTap: () => onChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 24,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textHint.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
