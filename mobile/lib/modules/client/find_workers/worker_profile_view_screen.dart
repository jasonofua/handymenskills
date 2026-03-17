import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../controllers/chat_controller.dart';
import '../../../controllers/review_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_cached_image.dart';
import '../../../widgets/common/app_shimmer.dart';
import '../../../widgets/common/app_empty_state.dart';
import '../../../widgets/common/app_snackbar.dart';

class WorkerProfileViewScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileViewScreen({super.key, required this.workerId});

  @override
  State<WorkerProfileViewScreen> createState() =>
      _WorkerProfileViewScreenState();
}

class _WorkerProfileViewScreenState extends State<WorkerProfileViewScreen> {
  final _workerRepo = Get.find<WorkerRepository>();
  final _favoriteRepo = Get.find<FavoriteRepository>();
  final _reviewController = Get.find<ReviewController>();

  final RxMap<String, dynamic> _profile = <String, dynamic>{}.obs;
  final RxBool _isLoading = true.obs;
  final RxBool _isSaved = false.obs;
  final RxBool _isSavingFavorite = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    try {
      _isLoading.value = true;
      final data = await _workerRepo.getWorkerProfile(widget.workerId);
      if (data != null) {
        _profile.assignAll(data);
        // Use the resolved auth user_id for reviews and favorites
        final authUserId = data['user_id']?.toString() ?? widget.workerId;
        _checkSaved();
        _reviewController.loadReviews(authUserId, refresh: true);
      }
    } catch (e) {
      AppSnackbar.error('Failed to load worker profile');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _checkSaved() async {
    try {
      _isSaved.value = await _favoriteRepo.isWorkerSaved(widget.workerId);
    } catch (e) {
      debugPrint('WorkerProfileView: Failed to check saved status: $e');
    }
  }

  Future<void> _toggleSave() async {
    try {
      _isSavingFavorite.value = true;
      if (_isSaved.value) {
        await _favoriteRepo.unsaveWorker(widget.workerId);
        _isSaved.value = false;
        AppSnackbar.success('Worker removed from favorites');
      } else {
        await _favoriteRepo.saveWorker(widget.workerId);
        _isSaved.value = true;
        AppSnackbar.success('Worker saved to favorites');
      }
    } catch (e) {
      AppSnackbar.error('Failed to update favorites');
    } finally {
      _isSavingFavorite.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_isLoading.value) {
          return _buildLoadingState();
        }

        if (_profile.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Profile not found',
              subtitle: 'This worker profile is not available.',
            ),
          );
        }

        return _buildContent();
      }),
      bottomNavigationBar: Obx(() {
        if (_isLoading.value || _profile.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildActionBar();
      }),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(expandedHeight: 200),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AppShimmer(height: 120, borderRadius: AppDimensions.cardRadius),
              const SizedBox(height: AppDimensions.md),
              AppShimmer(height: 80, borderRadius: AppDimensions.cardRadius),
              const SizedBox(height: AppDimensions.md),
              AppShimmer(height: 150, borderRadius: AppDimensions.cardRadius),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final name = _profile['profiles']?['full_name']?.toString() ??
        _profile['full_name']?.toString() ?? 'Worker';
    final avatarUrl = _profile['profiles']?['avatar_url']?.toString() ??
        _profile['avatar_url']?.toString();
    final headline = _profile['headline']?.toString() ?? '';
    final bio = _profile['bio']?.toString() ?? '';
    final isVerified = _profile['verification_status'] == 'verified';
    final rating = _profile['average_rating'];
    final totalReviews = _profile['total_reviews'] ?? 0;
    final totalJobs = _profile['completed_jobs'] ?? _profile['total_jobs'] ?? 0;
    final workerSkills = _profile['worker_skills'] as List? ?? [];
    final portfolioImages = _profile['portfolio_images'] as List? ?? [];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          actions: [
            Obx(() => IconButton(
              onPressed: _isSavingFavorite.value ? null : _toggleSave,
              icon: Icon(
                _isSaved.value ? Icons.favorite : Icons.favorite_border,
                color: _isSaved.value ? AppColors.error : null,
              ),
            )),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    AppAvatar(
                      imageUrl: avatarUrl,
                      name: name,
                      size: AppDimensions.avatarXl,
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.h3.copyWith(color: AppColors.white),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.white, size: 20),
                        ],
                      ],
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        headline,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (rating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < (rating is num ? rating.round() : 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 18,
                            color: AppColors.ratingStar,
                          )),
                          const SizedBox(width: 8),
                          Text(
                            '($totalReviews reviews)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStatsRow(rating, totalReviews, totalJobs),
              const SizedBox(height: AppDimensions.md),
              if (bio.isNotEmpty) ...[
                _buildAboutSection(bio),
                const SizedBox(height: AppDimensions.md),
              ],
              if (rating != null)
                _buildRatingBreakdown(rating, totalReviews),
              if (rating != null) const SizedBox(height: AppDimensions.md),
              if (workerSkills.isNotEmpty) ...[
                _buildSkillsSection(workerSkills),
                const SizedBox(height: AppDimensions.md),
              ],
              if (portfolioImages.isNotEmpty) ...[
                _buildPortfolioSection(portfolioImages),
                const SizedBox(height: AppDimensions.md),
              ],
              _buildReviewsSection(),
              const SizedBox(height: AppDimensions.xxl),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(dynamic rating, dynamic totalReviews, dynamic totalJobs) {
    final yearsExp = _profile['years_experience'] ?? _profile['experience_years'];

    return AppCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    totalJobs.toString(),
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text('JOBS', style: AppTextStyles.sectionHeader),
                ],
              ),
            ),
            Container(width: 1, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  Text(
                    yearsExp != null ? '${yearsExp}y' : 'N/A',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text('EXP', style: AppTextStyles.sectionHeader),
                ],
              ),
            ),
            Container(width: 1, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  Text(
                    rating != null
                        ? (rating is num ? rating.toStringAsFixed(1) : rating.toString())
                        : 'N/A',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text('RATING', style: AppTextStyles.sectionHeader),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ABOUT ME', style: AppTextStyles.sectionHeader),
        const SizedBox(height: AppDimensions.sm),
        AppCard(
          child: Text(bio, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildRatingBreakdown(dynamic rating, dynamic totalReviews) {
    final ratingNum = rating is num ? rating.toDouble() : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rating', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Column(
                children: [
                  Text(
                    ratingNum.toStringAsFixed(1),
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < ratingNum.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 18,
                        color: AppColors.ratingStar,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews reviews',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    // Approximate distribution for display
                    final fraction = star <= ratingNum.round()
                        ? (0.15 + (star / 5) * 0.7)
                        : 0.05;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: AppColors.ratingStar),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: fraction.clamp(0.0, 1.0).toDouble(),
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation(AppColors.ratingStar),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(List skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SKILLS & EXPERTISE', style: AppTextStyles.sectionHeader),
        const SizedBox(height: AppDimensions.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...skills.map<Widget>((ws) {
                final skill = ws is Map ? ws : <String, dynamic>{};
                final skillName = skill['skills']?['name']?.toString() ??
                    skill['name']?.toString() ?? '';
                final proficiency = skill['proficiency_level']?.toString() ?? '';
                final yearsExp = skill['years_experience'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(skillName, style: AppTextStyles.bodyMedium),
                      ),
                      if (proficiency.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _proficiencyColor(proficiency).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            proficiency[0].toUpperCase() + proficiency.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: _proficiencyColor(proficiency),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (yearsExp != null && yearsExp is num && yearsExp > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${yearsExp}y',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Color _proficiencyColor(String level) {
    switch (level.toLowerCase()) {
      case 'expert':
        return AppColors.primary;
      case 'advanced':
        return AppColors.info;
      case 'intermediate':
        return AppColors.secondary;
      case 'beginner':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildPortfolioSection(List images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROJECT PORTFOLIO', style: AppTextStyles.sectionHeader),
        const SizedBox(height: AppDimensions.sm),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final url = images[index]?.toString() ?? '';
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: AppCachedImage(
                  imageUrl: url,
                  width: 160,
                  height: 160,
                  borderRadius: AppDimensions.radiusMd,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RECENT REVIEWS', style: AppTextStyles.sectionHeader),
            TextButton(
              onPressed: () => context.push(AppRoutes.reviews.replaceFirst(':userId', widget.workerId)),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          if (_reviewController.isLoading.value) {
            return Column(
              children: List.generate(2, (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: AppShimmer.listItem(),
              )),
            );
          }

          final reviews = _reviewController.reviews.take(3).toList();

          if (reviews.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
              child: Center(
                child: Text(
                  'No reviews yet',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (_, index) {
              final review = reviews[index];
              return _ReviewCard(review: review);
            },
          );
        }),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final chatController = Get.find<ChatController>();
                  final conversationId = await chatController.startConversation(widget.workerId);
                  if (conversationId != null && context.mounted) {
                    context.push(AppRoutes.chatConversation.replaceFirst(':id', conversationId));
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  ),
                ),
                child: const Text('Contact'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  context.push(AppRoutes.clientPostJob);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hire Now',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review['profiles'] as Map<String, dynamic>?;
    final name = reviewer?['full_name']?.toString() ?? 'Anonymous';
    final avatarUrl = reviewer?['avatar_url']?.toString();
    final rating = review['overall_rating'] ?? 0;
    final comment = review['comment']?.toString() ?? '';
    final createdAt = review['created_at']?.toString() ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                imageUrl: avatarUrl,
                name: name,
                size: AppDimensions.avatarSm,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.labelMedium),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < (rating is num ? rating.toInt() : 0)
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: AppColors.ratingStar,
                        )),
                        const SizedBox(width: 8),
                        Text(_formatDate(createdAt), style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              comment,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return '';
    }
  }
}
