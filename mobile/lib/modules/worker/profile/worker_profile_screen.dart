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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _workerProfileController.loadWorkerProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
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
                _buildStatsRow(profile),
                const SizedBox(height: AppDimensions.lg),
                _buildAboutSection(profile),
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
    final totalReviews = profile['total_reviews'] ?? 0;
    final verificationStatus = profile['verification_status'] as String?;
    final isVerified = verificationStatus == 'verified';

    return Center(
      child: Column(
        children: [
          // -- Large circular avatar with green accent ring --
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: AppDimensions.avatarXl,
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // -- Name + verified badge --
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: AppDimensions.xs),
                const Icon(Icons.verified,
                    color: AppColors.info, size: 22),
              ],
            ],
          ),

          // -- Headline / specialty --
          if (headline.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              headline,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppDimensions.sm),

          // -- Star rating + review count --
          if (avgRating > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (index) {
                  final starValue = index + 1;
                  if (avgRating >= starValue) {
                    return const Icon(Icons.star,
                        color: AppColors.ratingStar, size: 20);
                  } else if (avgRating >= starValue - 0.5) {
                    return const Icon(Icons.star_half,
                        color: AppColors.ratingStar, size: 20);
                  } else {
                    return const Icon(Icons.star_border,
                        color: AppColors.ratingStar, size: 20);
                  }
                }),
                const SizedBox(width: 6),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.ratingStar,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            )
          else
            Text('No ratings yet', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> profile) {
    final jobsCompleted = profile['jobs_completed'] ?? 0;
    final avgRating = (profile['avg_rating'] ?? 0.0).toDouble();
    final verificationStatus = profile['verification_status'] as String?;
    final isVerified = verificationStatus == 'verified';

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'JOBS',
            value: jobsCompleted.toString(),
            icon: Icons.check_circle_outline,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'RATING',
            value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
            icon: Icons.star,
            color: AppColors.ratingStar,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'VERIFIED',
            value: isVerified ? 'Yes' : 'No',
            icon: Icons.verified_user_outlined,
            color: isVerified ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> profile) {
    final bio = profile['bio'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ABOUT ME', style: AppTextStyles.sectionHeader),
        const SizedBox(height: AppDimensions.sm),
        AppCard(
          child: Text(
            bio.isNotEmpty
                ? bio
                : 'No bio added yet. Edit your profile to tell clients about yourself.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: bio.isNotEmpty
                  ? AppColors.textPrimary
                  : AppColors.textHint,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SKILLS', style: AppTextStyles.sectionHeader),
        const SizedBox(height: AppDimensions.sm),
        Obx(() {
          final skills = _workerProfileController.workerSkills;

          if (skills.isEmpty) {
            return AppCard(
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
            Text('PORTFOLIO', style: AppTextStyles.sectionHeader),
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
          )
        else
          // Horizontal scroll portfolio
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppDimensions.sm),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  child: AppCachedImage(
                    imageUrl: images[index],
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.md,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(value, style: AppTextStyles.h4),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.sectionHeader.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
