import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_card.dart';

class JobPostedSuccessScreen extends StatelessWidget {
  final String? jobId;
  final String? jobTitle;

  const JobPostedSuccessScreen({
    super.key,
    this.jobId,
    this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Status', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutes.clientDashboard),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Success icon
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            // Title
            const Text(
              'Job Posted\nSuccessfully!',
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.md),

            // Description
            Text(
              jobTitle != null
                  ? 'Your job post for "$jobTitle" is now live. Skilled handymen in your area have been notified and can now apply to your project.'
                  : 'Your job post is now live. Skilled handymen in your area have been notified and can now apply to your project.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.xl),

            // View My Job button
            AppButton(
              label: 'View My Job',
              onPressed: () {
                if (jobId != null) {
                  context.go(
                      AppRoutes.clientJobDetail.replaceFirst(':id', jobId!));
                } else {
                  context.go(AppRoutes.clientMyJobs);
                }
              },
            ),
            const SizedBox(height: AppDimensions.md),

            // Go to Dashboard button
            AppButton(
              label: 'Go to Dashboard',
              type: AppButtonType.outline,
              onPressed: () => context.go(AppRoutes.clientDashboard),
            ),
            const SizedBox(height: AppDimensions.xl),

            // What's next section
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("What's next?",
                            style: AppTextStyles.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          "We'll alert you via push notification as soon as a professional shows interest.",
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Pro tip section
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius:
                    BorderRadius.circular(AppDimensions.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pro Tip: Complete your profile',
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Users with a profile photo get 40% more applications on average.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }
}
