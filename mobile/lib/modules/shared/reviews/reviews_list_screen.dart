import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/review_controller.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_loading.dart';
import '../../../widgets/common/app_shimmer.dart';

class ReviewsListScreen extends StatefulWidget {
  final String userId;

  const ReviewsListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  final ReviewController _reviewController = Get.find<ReviewController>();

  @override
  void initState() {
    super.initState();
    _reviewController.loadReviews(widget.userId, refresh: true);
  }

  Future<void> _onRefresh() async {
    await _reviewController.loadReviews(widget.userId, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
      ),
      body: Obx(() {
        if (_reviewController.isLoading.value &&
            _reviewController.reviews.isEmpty) {
          return _buildShimmerList();
        }

        if (_reviewController.reviews.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              children: const [
                SizedBox(height: 120),
                AppEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No reviews yet',
                  subtitle: 'Reviews will appear here once received.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              _RatingSummary(reviews: _reviewController.reviews),
              const SizedBox(height: AppDimensions.lg),
              ..._reviewController.reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.md,
                  ),
                  child: _ReviewCard(review: review),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShimmerList() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      children: [
        AppShimmer.card(),
        const SizedBox(height: AppDimensions.md),
        ...List.generate(4, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.md),
            child: AppShimmer.card(),
          );
        }),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;

  const _RatingSummary({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    final totalCount = reviews.length;
    double totalRating = 0;
    final Map<int, int> breakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (final review in reviews) {
      final rating = (review['overall_rating'] as num?)?.toInt() ?? 0;
      totalRating += rating;
      if (breakdown.containsKey(rating)) {
        breakdown[rating] = breakdown[rating]! + 1;
      }
    }

    final averageRating = totalRating / totalCount;

    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average rating display
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: _buildStarIcons(averageRating),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    '$totalCount ${totalCount == 1 ? 'review' : 'reviews'}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: AppDimensions.lg),
              // Breakdown bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = breakdown[star] ?? 0;
                    final percentage =
                        totalCount > 0 ? count / totalCount : 0.0;
                    return _RatingBar(
                      starCount: star,
                      percentage: percentage,
                      count: count,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStarIcons(double rating) {
    return List.generate(5, (index) {
      if (index < rating.floor()) {
        return const Icon(
          Icons.star,
          size: 18,
          color: AppColors.ratingStar,
        );
      } else if (index < rating.ceil() && rating % 1 != 0) {
        return const Icon(
          Icons.star_half,
          size: 18,
          color: AppColors.ratingStar,
        );
      } else {
        return const Icon(
          Icons.star_border,
          size: 18,
          color: AppColors.ratingStar,
        );
      }
    });
  }
}

class _RatingBar extends StatelessWidget {
  final int starCount;
  final double percentage;
  final int count;

  const _RatingBar({
    required this.starCount,
    required this.percentage,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '$starCount',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.star,
            size: 12,
            color: AppColors.ratingStar,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusFull,
              ),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: AppColors.ratingStar,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer =
        review['reviewer'] as Map<String, dynamic>? ?? {};
    final String reviewerName = reviewer['full_name'] ?? 'Anonymous';
    final String? reviewerAvatar = reviewer['avatar_url'];
    final int rating = (review['overall_rating'] as num?)?.toInt() ?? 0;
    final String comment = review['comment'] ?? '';
    final DateTime? createdAt =
        DateTime.tryParse(review['created_at'] ?? '');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: reviewerAvatar,
                name: reviewerName,
                size: AppDimensions.avatarSm + 8,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: AppColors.ratingStar,
                          );
                        }),
                        const SizedBox(width: AppDimensions.sm),
                        if (createdAt != null)
                          Text(
                            DateFormat('MMM d, yyyy').format(createdAt),
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            Text(
              comment,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
          // Category ratings if present
          if (_hasCategoryRatings()) ...[
            const SizedBox(height: AppDimensions.md),
            const Divider(),
            const SizedBox(height: AppDimensions.sm),
            _buildCategoryRatings(),
          ],
        ],
      ),
    );
  }

  bool _hasCategoryRatings() {
    return review['quality_rating'] != null ||
        review['communication_rating'] != null ||
        review['punctuality_rating'] != null ||
        review['value_rating'] != null;
  }

  Widget _buildCategoryRatings() {
    final categories = <MapEntry<String, int>>[];

    if (review['quality_rating'] != null) {
      categories.add(MapEntry(
        'Quality',
        (review['quality_rating'] as num).toInt(),
      ));
    }
    if (review['communication_rating'] != null) {
      categories.add(MapEntry(
        'Communication',
        (review['communication_rating'] as num).toInt(),
      ));
    }
    if (review['punctuality_rating'] != null) {
      categories.add(MapEntry(
        'Punctuality',
        (review['punctuality_rating'] as num).toInt(),
      ));
    }
    if (review['value_rating'] != null) {
      categories.add(MapEntry(
        'Value',
        (review['value_rating'] as num).toInt(),
      ));
    }

    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.sm,
      children: categories.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.key,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppDimensions.xs),
            ...List.generate(5, (index) {
              return Icon(
                index < entry.value ? Icons.star : Icons.star_border,
                size: 12,
                color: AppColors.ratingStar,
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}
