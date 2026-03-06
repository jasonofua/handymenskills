import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../controllers/subscription_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_shimmer.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionController = Get.find<SubscriptionController>();

  @override
  void initState() {
    super.initState();
    _subscriptionController.loadMySubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _subscriptionController.loadMySubscription(),
        child: Obx(() {
          if (_subscriptionController.isLoading.value &&
              _subscriptionController.currentSubscription.value == null) {
            return AppShimmer.list(count: 3);
          }

          final subscription =
              _subscriptionController.currentSubscription.value;
          final isActive = _subscriptionController.isActive;
          final isGrace = _subscriptionController.isGracePeriod;

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            children: [
              if (subscription != null && (isActive || isGrace))
                _buildActiveSubscriptionCard(subscription)
              else
                _buildNoSubscriptionCard(),
              const SizedBox(height: AppDimensions.lg),
              _buildActionButton(isActive || isGrace),
              const SizedBox(height: AppDimensions.lg),
              _buildBenefitsSection(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(Map<String, dynamic> subscription) {
    final planName = subscription['plan']?['name'] ??
        subscription['plan_name'] ??
        'Current Plan';
    final daysRemaining = _subscriptionController.daysRemaining;
    final expiresAt = DateTime.tryParse(subscription['expires_at'] ?? '');
    final isGrace = _subscriptionController.isGracePeriod;

    return AppCard(
      color: isGrace
          ? AppColors.warning.withValues(alpha: 0.08)
          : AppColors.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGrace
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGrace ? Icons.warning_amber : Icons.workspace_premium,
                  color: isGrace ? AppColors.warning : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planName, style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGrace
                            ? AppColors.warning.withValues(alpha: 0.2)
                            : AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull),
                      ),
                      child: Text(
                        isGrace ? 'Grace Period' : 'Active',
                        style: AppTextStyles.labelSmall.copyWith(
                          color:
                              isGrace ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          const Divider(),
          const SizedBox(height: AppDimensions.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoColumn(
                label: 'Days Remaining',
                value: daysRemaining > 0 ? daysRemaining.toString() : '0',
              ),
              if (expiresAt != null)
                _InfoColumn(
                  label: 'Expires',
                  value: _formatDate(expiresAt),
                ),
            ],
          ),
          if (isGrace) ...[
            const SizedBox(height: AppDimensions.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'Your subscription has expired. You have ${AppConstants.gracePeriodDays} days to renew before losing access.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionCard() {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'No Active Subscription',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Subscribe to start applying to jobs and connect with clients.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool hasSubscription) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.workerPlanSelection),
        icon: Icon(hasSubscription ? Icons.autorenew : Icons.upgrade),
        label: Text(hasSubscription ? 'Renew Plan' : 'Choose a Plan'),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subscription Benefits', style: AppTextStyles.h4),
        const SizedBox(height: AppDimensions.sm),
        AppCard(
          child: Column(
            children: [
              _BenefitItem(
                icon: Icons.work_outline,
                title: 'Apply to Jobs',
                description: 'Submit applications to available jobs',
              ),
              const Divider(),
              _BenefitItem(
                icon: Icons.search,
                title: 'Appear in Search',
                description: 'Clients can find you in worker searches',
              ),
              const Divider(),
              _BenefitItem(
                icon: Icons.chat_outlined,
                title: 'Direct Messaging',
                description: 'Chat directly with clients',
              ),
              const Divider(),
              _BenefitItem(
                icon: Icons.star_outline,
                title: 'Build Reputation',
                description: 'Collect reviews and grow your profile',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.labelLarge),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium),
                const SizedBox(height: 2),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
