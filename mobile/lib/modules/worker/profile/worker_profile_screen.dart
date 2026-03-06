import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../controllers/worker_profile_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_avatar.dart';
import '../../../widgets/common/app_cached_image.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_chip.dart';
import '../../../widgets/common/app_error_widget.dart';
import '../../../widgets/common/app_shimmer.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _workerProfileController = Get.find<WorkerProfileController>();
  final _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _workerProfileController.loadWorkerProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _workerProfileController.loadWorkerProfile(),
        child: Obx(() {
          if (_workerProfileController.isLoading.value &&
              _workerProfileController.workerProfile.isEmpty) {
            return AppShimmer.list(count: 5);
          }

          final profile = _workerProfileController.workerProfile;

          if (profile.isEmpty) {
            return AppErrorWidget(
              message: 'Failed to load profile',
              onRetry: () => _workerProfileController.loadWorkerProfile(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(profile),
                const SizedBox(height: AppDimensions.lg),
                _buildStatsSection(profile),
                const SizedBox(height: AppDimensions.lg),
                _buildSkillsSection(),
                const SizedBox(height: AppDimensions.lg),
                _buildPortfolioSection(profile),
                const SizedBox(height: AppDimensions.lg),
                _buildEditButton(),
                const SizedBox(height: AppDimensions.xxl),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> profile) {
    final name = _authController.userName;
    final avatarUrl = _authController.userAvatar;
    final headline = profile['headline'] as String? ?? '';
    final avgRating = (profile['avg_rating'] ?? 0.0).toDouble();
    final verificationStatus = profile['verification_status'] as String?;
    final isVerified = verificationStatus == 'verified';

    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: avatarUrl,
                name: name,
                size: AppDimensions.avatarXl,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: AppDimensions.xs),
                          const Icon(Icons.verified,
                              color: AppColors.info, size: 20),
                        ],
                      ],
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        headline,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.sm),
                    if (avgRating > 0)
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final starValue = index + 1;
                            if (avgRating >= starValue) {
                              return const Icon(Icons.star,
                                  color: AppColors.ratingStar, size: 18);
                            } else if (avgRating >= starValue - 0.5) {
                              return const Icon(Icons.star_half,
                                  color: AppColors.ratingStar, size: 18);
                            } else {
                              return const Icon(Icons.star_border,
                                  color: AppColors.ratingStar, size: 18);
                            }
                          }),
                          const SizedBox(width: 4),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.ratingStar,
                            ),
                          ),
                        ],
                      )
                    else
                      Text('No ratings yet', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> profile) {
    final jobsCompleted = profile['jobs_completed'] ?? 0;
    final totalReviews = profile['total_reviews'] ?? 0;
    final completionRate = (profile['completion_rate'] ?? 0.0).toDouble();

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Jobs Done',
            value: jobsCompleted.toString(),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatTile(
            label: 'Reviews',
            value: totalReviews.toString(),
            icon: Icons.rate_review_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatTile(
            label: 'Completion',
            value: '${completionRate.toStringAsFixed(0)}%',
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skills', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          final skills = _workerProfileController.workerSkills;

          if (skills.isEmpty) {
            return AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Row(
                  children: [
                    Icon(Icons.handyman_outlined,
                        color: AppColors.textHint, size: 24),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'No skills added yet. Edit your profile to add skills.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Wrap(
            spacing: AppDimensions.sm,
            runSpacing: AppDimensions.sm,
            children: skills.map((skill) {
              final skillName =
                  skill['skill']?['name'] ?? skill['name'] ?? 'Skill';
              final experienceYears = skill['experience_years'];
              final label = experienceYears != null
                  ? '$skillName (${experienceYears}yr)'
                  : skillName;
              return AppChip(
                label: label,
                isSelected: true,
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildPortfolioSection(Map<String, dynamic> profile) {
    final images = List<String>.from(profile['portfolio_images'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Portfolio', style: AppTextStyles.h4),
            if (images.isNotEmpty)
              Text(
                '${images.length} photos',
                style: AppTextStyles.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        if (images.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.sm),
              child: Row(
                children: [
                  Icon(Icons.photo_library_outlined,
                      color: AppColors.textHint, size: 24),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'No portfolio images yet. Add photos of your work.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppDimensions.sm,
              crossAxisSpacing: AppDimensions.sm,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                child: AppCachedImage(
                  imageUrl: images[index],
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: AppDimensions.radiusMd,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.workerEditProfile),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Profile'),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.sm),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: AppDimensions.xs),
          Text(value, style: AppTextStyles.h4),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
